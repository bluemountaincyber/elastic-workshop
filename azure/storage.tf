resource "azurerm_storage_account" "el_sa" {
  name                     = "elastic${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.el_rg.name
  location                 = azurerm_resource_group.el_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

data "azurerm_storage_account_sas" "el_sas" {
  connection_string = azurerm_storage_account.el_sa.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = true
    container = false
    object    = false
  }

  services {
    blob  = false
    queue = false
    table = true
    file  = false
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "8760h")

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = true
    tag     = true
    filter  = true
  }
}
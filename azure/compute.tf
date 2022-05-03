resource "azurerm_linux_virtual_machine" "elastic" {
  name                = "elastic"
  resource_group_name = azurerm_resource_group.el_rg.name
  location            = azurerm_resource_group.el_rg.location
  size                = "Standard_B2s"
  admin_username      = "elastic"
  admin_password      = var.elastic_vm_password
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.el_nic.id]
  custom_data = base64encode(templatefile("${path.module}/userdata/elastic.sh", {
    PASSWORD = var.elastic_app_password,
    URL = "elastic${random_string.suffix.result}.${var.az_location}.cloudapps.azure.com",
    CONNSTRING = azurerm_eventhub_authorization_rule.auth_rule.primary_connection_string
  }))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "victim" {
  name                = "victim"
  resource_group_name = azurerm_resource_group.el_rg.name
  location            = azurerm_resource_group.el_rg.location
  size                = "Standard_B1s"
  admin_username      = "elastic"
  admin_password      = var.victim_vm_password
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.victim_nic.id]
  custom_data = base64encode(file("${path.module}/userdata/victim.sh"))

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}
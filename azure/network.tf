resource "random_string" "suffix" {
  length  = 16
  special = false
  upper   = false
  lower   = true
  number  = true
}

resource "azurerm_virtual_network" "el_vnet" {
  name                = "el-vnet"
  location            = azurerm_resource_group.el_rg.location
  resource_group_name = azurerm_resource_group.el_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "el_subnet" {
  name                 = "el-subnet"
  resource_group_name  = azurerm_resource_group.el_rg.name
  virtual_network_name = azurerm_virtual_network.el_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "el_pip" {
  name                = "el-pip"
  resource_group_name = azurerm_resource_group.el_rg.name
  location            = azurerm_resource_group.el_rg.location
  allocation_method   = "Static"
  domain_name_label = "elastic${random_string.suffix.result}"
}

resource "azurerm_public_ip" "victim_pip" {
  name                = "victim-pip"
  resource_group_name = azurerm_resource_group.el_rg.name
  location            = azurerm_resource_group.el_rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "el_nsg" {
  name                = "el-nsg"
  location            = azurerm_resource_group.el_rg.location
  resource_group_name = azurerm_resource_group.el_rg.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5601"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "victim_nsg" {
  name                = "victim-nsg"
  location            = azurerm_resource_group.el_rg.location
  resource_group_name = azurerm_resource_group.el_rg.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "el_nic" {
  name                = "el-nic"
  location            = azurerm_resource_group.el_rg.location
  resource_group_name = azurerm_resource_group.el_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.el_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.el_pip.id
  }
}

resource "azurerm_network_interface" "victim_nic" {
  name                = "victim-nic"
  location            = azurerm_resource_group.el_rg.location
  resource_group_name = azurerm_resource_group.el_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.el_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.victim_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "el_nic_nsg" {
  network_interface_id      = azurerm_network_interface.el_nic.id
  network_security_group_id = azurerm_network_security_group.el_nsg.id
}

resource "azurerm_network_interface_security_group_association" "victim_nic_nsg" {
  network_interface_id      = azurerm_network_interface.victim_nic.id
  network_security_group_id = azurerm_network_security_group.victim_nsg.id
}
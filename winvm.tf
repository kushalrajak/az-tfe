resource "azurerm_network_interface" "winvm-nic" {
  name                = "${var.winvm}-nic"
  resource_group_name = var.rg-name
  location            = var.rg-loc
  ip_configuration {
    name                          = "${var.winvm}-ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.winvm-default.id
    public_ip_address_id          = azurerm_public_ip.winvmpip.id
  }
}

resource "azurerm_virtual_network" "winvm-vnet" {
  name                = "${var.winvm}-vnet"
  resource_group_name = var.rg-name
  location            = var.rg-loc
  address_space       = ["20.0.0.0/16"]
}

resource "azurerm_subnet" "winvm-default" {
  name                 = "winvm-default"
  address_prefixes     = ["20.0.0.0/24"]
  virtual_network_name = azurerm_virtual_network.winvm-vnet.name
  resource_group_name  = var.rg-name
}

resource "azurerm_public_ip" "winvmpip" {
  name                = "${var.winvm}-pip"
  resource_group_name = var.rg-name
  location            = var.rg-loc
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "winvmnsg" {
  name                = "${var.winvm}-nsg"
  resource_group_name = var.rg-name
  location            = var.rg-loc

  security_rule {
    name                       = "RDP-allow"
    source_address_prefix      = "*"
    destination_address_prefix = "20.0.0.0/24"
    source_port_range          = "*"
    destination_port_range     = "3389"
    protocol                   = "Tcp"
    access                     = "Allow"
    priority                   = "300"
    direction                  = "Inbound"
  }
  security_rule {
    name                       = "Deny-All-Inbound"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    protocol                   = "*"
    access                     = "Deny"
    priority                   = "4094"
    direction                  = "Inbound"
  }
  security_rule {
    name                       = "Deny-All-Outbound"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    protocol                   = "*"
    access                     = "Deny"
    priority                   = "4094"
    direction                  = "Outbound"
  }
  security_rule {
    name                       = "ADDC-TCP-Outbound"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/24"
    source_port_range          = "*"
    destination_port_ranges    = ["53", "88", "135", "389", "445", "464", "636", "3268", "3269", "49152-65535"]
    protocol                   = "Tcp"
    access                     = "Allow"
    priority                   = "1000"
    direction                  = "Outbound"
  }
  security_rule {
    name                       = "ADDC-UDP-Outbound"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/24"
    source_port_range          = "*"
    destination_port_ranges    = ["53", "88", "389", "445", "464"]
    protocol                   = "Udp"
    access                     = "Allow"
    priority                   = "1500"
    direction                  = "Outbound"
  }
}

resource "azurerm_windows_virtual_machine" "winvm" {
  name                  = var.winvm
  resource_group_name   = var.rg-name
  location              = var.rg-loc
  admin_username        = "azureadmin"
  admin_password        = "Password@123!"
  size                  = "Standard_B2s"
  network_interface_ids = [azurerm_network_interface.winvm-nic.id]
  computer_name         = var.winvm
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

output "pipout-winvm" {
  value = azurerm_public_ip.winvmpip.ip_address
}

resource "azurerm_subnet_network_security_group_association" "nsg-associate-winvm" {
  network_security_group_id = azurerm_network_security_group.winvmnsg.id
  subnet_id                 = azurerm_subnet.winvm-default.id
}
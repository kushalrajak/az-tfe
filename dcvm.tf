resource "azurerm_network_interface" "dcvm-nic" {
  name                = "${var.dcvm}-nic"
  resource_group_name = var.rg-name
  location            = var.rg-loc
  ip_configuration {
    name                          = "${var.dcvm}-ipconfig"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.dc-default.id
    public_ip_address_id          = azurerm_public_ip.dcvmpip.id
  }
}

resource "azurerm_virtual_network" "dcvm-vnet" {
  name                = "${var.dcvm}-vnet"
  resource_group_name = var.rg-name
  location            = var.rg-loc
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "dc-default" {
  name                 = "dc-default"
  address_prefixes     = ["10.0.0.0/24"]
  virtual_network_name = azurerm_virtual_network.dcvm-vnet.name
  resource_group_name  = var.rg-name
}

resource "azurerm_public_ip" "dcvmpip" {
  name                = "${var.dcvm}-pip"
  resource_group_name = var.rg-name
  location            = var.rg-loc
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "dcvmnsg" {
  name                = "${var.dcvm}-nsg"
  resource_group_name = var.rg-name
  location            = var.rg-loc

  security_rule {
    name                       = "RDP-allow"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/24"
    source_port_range          = "*"
    destination_port_range     = "3389"
    protocol                   = "Tcp"
    access                     = "Allow"
    priority                   = "4095"
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
    priority                   = "4096"
    direction                  = "Inbound"
  }
  security_rule {
    name                       = "ADDC-TCP-IN"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/16"
    source_port_range          = "*"
    destination_port_ranges    = ["53", "135", "88", "389", "445", "464", "636", "3268", "3269", "49152-65535"]
    protocol                   = "Tcp"
    access                     = "Allow"
    priority                   = "1000"
    direction                  = "Inbound"
  }
  security_rule {
    name                       = "ADDC-UDP-IN"
    source_address_prefix      = "*"
    destination_address_prefix = "10.0.0.0/16"
    source_port_range          = "*"
    destination_port_ranges    = ["53", "88", "389", "464"]
    protocol                   = "Udp"
    access                     = "Allow"
    priority                   = "1500"
    direction                  = "Inbound"
  }
}

resource "azurerm_windows_virtual_machine" "dcvm" {
  name                  = var.dcvm
  resource_group_name   = var.rg-name
  location              = var.rg-loc
  admin_username        = "azureadmin"
  admin_password        = "Password@123!"
  size                  = "Standard_B2s"
  network_interface_ids = [azurerm_network_interface.dcvm-nic.id]
  computer_name         = var.dcvm
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

output "pipout" {
  value = azurerm_public_ip.dcvmpip.ip_address
}

resource "azurerm_subnet_network_security_group_association" "nsg-associate" {
  network_security_group_id = azurerm_network_security_group.dcvmnsg.id
  subnet_id                 = azurerm_subnet.dc-default.id
}

resource "azurerm_virtual_machine_extension" "create_ad_forest" {
  name                 = "Create-ActiveDirectory-Forest"
  virtual_machine_id   = azurerm_windows_virtual_machine.dcvm.id   # ← your VM name
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  # Public settings - can be empty or used for non-sensitive data
  settings = jsonencode({
    "timestamp" = timestamp()   # Helps force re-run if you update the script
  })

  # Protected settings - contains the actual command with password
  protected_settings = jsonencode({
    "commandToExecute" = "powershell.exe -ExecutionPolicy Unrestricted -Command \"${local.powershell_command}\""
  })

  timeouts {
    create  = "2h"     # Important for AD DS forest creation
    update  = "30m"
    delete  = "30m"
  }

  depends_on = [azurerm_windows_virtual_machine.dcvm]
}

locals {
  domain_name    = "kush.local"          # Change as needed
  netbios_name   = "kush"
  safe_mode_pass = "YourVeryStrongP@ssw0rd123!"   # ← Use Terraform variable in production!

  powershell_command = <<EOT
    Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools
  EOT
}
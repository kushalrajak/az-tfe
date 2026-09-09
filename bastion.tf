resource "azurerm_subnet" "bastion-sub" {
  name                 = "AzureBastionSubnet"
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.dcvm-vnet.name
}

resource "azurerm_public_ip" "bastion-pip" {
  name                = "bastion-pip"
  resource_group_name = var.rg-name
  location            = var.rg-loc
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "az-bastion" {
  name                = "az-bastion"
  resource_group_name = var.rg-name
  location            = var.rg-loc
  sku = "Standard"
  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion-sub.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
}

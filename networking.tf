# resource "azurerm_virtual_network_peering" "dcvm-winvm" {
#   name                      = "dcvm-winvm"
#   resource_group_name       = var.rg-name
#   virtual_network_name      = "azurerm_virtual_network.dcvm-vnet.name"
#   remote_virtual_network_id = azurerm_virtual_network.winvm-vnet.id
# }

resource "azurerm_virtual_network_peering" "dcpeer" {
  name                      = "dcvmpeer"
  resource_group_name       = var.rg-name
  remote_virtual_network_id = azurerm_virtual_network.winvm-vnet.id
  virtual_network_name      = azurerm_virtual_network.dcvm-vnet.name
}

resource "azurerm_virtual_network_peering" "winvmpeer" {
  name                      = "winvmpeer"
  resource_group_name       = var.rg-name
  remote_virtual_network_id = azurerm_virtual_network.dcvm-vnet.id
  virtual_network_name      = azurerm_virtual_network.winvm-vnet.name
}
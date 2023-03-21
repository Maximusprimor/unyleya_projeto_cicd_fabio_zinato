resource "azurerm_resource_group" "rg" {
  name                     = var.resource_group_name
  location                 = var.location
}

resource "azurerm_container_registry" "acr" {
  name                     = "unyleyaeadacr1"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  sku                      = "Standard"
  admin_enabled            = true
}

data "azurerm_container_registry" "acr" {
  name                     = azurerm_container_registry.acr.name
  resource_group_name      = azurerm_resource_group.rg.name

  depends_on = [azurerm_container_registry.acr]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "unyleyaeadaks1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = "unyleyaeadaks1"

  default_node_pool {
    name                  = "default"
    vm_size               = "Standard_D2_v2"
    enable_auto_scaling   = false
    node_count            = 1
    type                  = "VirtualMachineScaleSets"
    enable_node_public_ip = false
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_container_registry.acr]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "unyleyaeadnsg1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_rule" "nsr" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  
  depends_on = [azurerm_kubernetes_cluster.aks]  
}

resource "azurerm_role_assignment" "acrpull_role" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.aks]
}
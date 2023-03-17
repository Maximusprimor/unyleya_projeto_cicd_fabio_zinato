resource "azurerm_resource_group" "rg" {
  name                     = var.resource_group_name
  location                 = var.location
}

resource "azurerm_container_registry" "acr" {
  name                     = "unyleyaeadacr"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Basic"
  admin_enabled            = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "unyleyaeadaks"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = "unyleyaeadaks"
  enable_attach_acr   = true
  scope               = azurerm_container_registry.acr.id

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  linux_profile {
    admin_username = "unyleyauser"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  depends_on = [azurerm_container_registry.acr]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "unyleyaeadnsg"
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
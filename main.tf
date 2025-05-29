resource "random_password" "pwd" {
  length  = 16
  special = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_key_vault" "kv" {
  name                        = var.keyvault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  sku_name                    = "standard"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization   = true
  purge_protection_enabled    = false
}

# ✅ Grant current user (you) Key Vault Administrator access to prevent future lockout
resource "azurerm_role_assignment" "current_user_kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# 🔐 Wait until access is assigned before creating secret
resource "azurerm_key_vault_secret" "example_secret" {
  name         = "my-secret-names"
  value        = random_password.pwd.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.current_user_kv_admin]
}

resource "azurerm_mssql_server" "sqlserver" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = "centralus"
  version                      = "12.0"
  administrator_login          = var.sql_admin_user
  administrator_login_password = azurerm_key_vault_secret.example_secret.value
}

resource "azurerm_mssql_database" "sqldb" {
  name                = "aks-python-dbs"
  max_size_gb         = 2
  server_id = azurerm_mssql_server.sqlserver.id
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aksClusterDemo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aksdemo"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}

# 🚀 Grant AKS Managed Identity access to ACR (to pull container images)
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# 🔐 Grant AKS access to Key Vault secrets
resource "azurerm_role_assignment" "aks_kv_secret_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# 🧪 Optional output of kubeconfig
output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

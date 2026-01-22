########################################
# DATA SOURCES
#########################################

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Get current user's object ID for Key Vault permissions
data "azuread_client_config" "current" {}

#########################################
# RESOURCE GROUP
#########################################

resource "azurerm_resource_group" "main" {
  name     = "k8s-vm-rg"
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

#########################################
# AZURE CONTAINER REGISTRY
#########################################

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

#########################################
# USER ASSIGNED MANAGED IDENTITY
#########################################

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "my-k8s-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

#########################################
# AKS CLUSTER
#########################################

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.cluster_name}-dns"
  sku_tier            = "Free"

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.vm_size
    min_count           = var.min_node_count
    max_count           = var.max_node_count
    os_disk_size_gb     = 30
    type                = "VirtualMachineScaleSets"

    # 👇 INCREASE max_pods per node
    max_pods = 100 # Default is 30, max is 250

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"

    # 👇 ADD OVERLAY MODE (Azure CNI Overlay)
    network_plugin_mode = "overlay"

    # Pod CIDR for overlay network (doesn't consume VNet IPs)
    pod_cidr = "100.64.0.0/10" # Large private range for pods

    # Service CIDR (for ClusterIP services)
    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"

    # IP families (optional, for dual-stack)
    ip_versions = ["IPv4"]
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [
    azurerm_role_assignment.acr_pull, azurerm_resource_group.main
  ]
}

#########################################
# ROLE ASSIGNMENTS
#########################################

# Allow AKS to pull images from ACR
resource "azurerm_role_assignment" "acr_pull" {
  principal_id                     = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

#########################################
# FEDERATED IDENTITY CREDENTIAL
#########################################

resource "azurerm_federated_identity_credential" "aks_federated" {
  name                = "my-k8s-identity-fic"
  resource_group_name = azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.aks_identity.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  subject             = "system:serviceaccount:dev:dev-sa"
}

#########################################
# KEY VAULT
#########################################

resource "azurerm_key_vault" "kv" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  enable_rbac_authorization = true

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Grant current user Key Vault Secrets Officer role
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Grant managed identity Key Vault Secrets User role
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
}

#########################################
# KEY VAULT SECRETS
#########################################

resource "azurerm_key_vault_secret" "db_secrets" {
  for_each = var.db_secrets

  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_role_assignment.kv_secrets_officer
  ]
}

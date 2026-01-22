#########################################
# OUTPUTS
#########################################

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_kubeconfig" {
  description = "Kubeconfig for AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "acr_login_server" {
  description = "ACR login server"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_id" {
  description = "ACR ID"
  value       = azurerm_container_registry.acr.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.kv.vault_uri
}

output "managed_identity_client_id" {
  description = "Managed Identity Client ID (use in Kubernetes ServiceAccount)"
  value       = azurerm_user_assigned_identity.aks_identity.client_id
}

output "managed_identity_principal_id" {
  description = "Managed Identity Principal ID"
  value       = azurerm_user_assigned_identity.aks_identity.principal_id
}

output "oidc_issuer_url" {
  description = "OIDC Issuer URL"
  value       = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "tenant_id" {
  description = "Azure AD Tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}
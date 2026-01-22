variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "norwayeast"
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
  default     = "k8s-cluster"
}

variable "node_count" {
  description = "Initial node count"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum node count for autoscaling"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Maximum node count for autoscaling"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "VM size for nodes"
  type        = string
  default     = "Standard_D2as_v6"
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
  default     = "k8spractice"
}

variable "key_vault_name" {
  description = "Key Vault name (must be globally unique)"
  type        = string
  default     = "db-secrets-k8s"
}

variable "db_secrets" {
  description = "Database secrets to store in Key Vault"
  type        = map(string)
  default = {
    db-host     = "postgres"
    db-user     = "appuser"
    db-password = "apppassword"
    db-name     = "appdb"
  }

}

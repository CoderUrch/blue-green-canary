terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatedevops2025" # Must be globally unique
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

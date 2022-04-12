terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.97.0"
    }
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.5.1"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.2.2"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

provider "databricks" {
  host                        = format("https://%s", data.azurerm_databricks_workspace.dbr.workspace_url)
  azure_workspace_resource_id = data.azurerm_databricks_workspace.dbr.id
  azure_client_id             = var.client_id
  azure_client_secret         = var.client_secret
  azure_tenant_id             = var.tenant_id
}

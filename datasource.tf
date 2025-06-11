data "terraform_remote_state" "container_app_environment" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.remote_tfstate_rg
    storage_account_name = var.remote_tfstate_storage_account
    container_name       = var.remote_tfstate_container
    key                  = var.remote_tfstate_key
  }
}

# Reference our own state to get previous container images (useful during destroy)
data "terraform_remote_state" "self" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.state_storage_account_name
    storage_account_name = var.state_storage_account_name
    container_name       = "tfstate"
    key                  = "apps/${var.environment}/${local.app_config.name}"
  }

  defaults = {
    container_images = {}
  }
}



data "terraform_remote_state" "container_app_environment" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.remote_tfstate_rg
    storage_account_name = var.remote_tfstate_storage_account
    container_name       = var.remote_tfstate_container
    key                  = var.remote_tfstate_key
  }
}



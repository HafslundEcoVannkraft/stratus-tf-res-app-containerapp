#
# This file defines variables used in the deployment.
#
variable "subscription_id" {
  description = "The subscription ID for the Azure provider"
  type        = string
}

variable "location" {
  description = "The location of the resources"
  type        = string
}

variable "code_name" {
  type        = string
  description = "The code name for the product team"
}

variable "environment" {
  type        = string
  description = "The environment"
}

variable "state_storage_account_name" {
  type        = string
  description = "The name of the gitops storage account"
}

# Wrapper module spesific variables set at GitHub Action runtime:

variable "remote_tfstate_rg" {
  type        = string
  description = "The resource group name for the remote Terraform state"
  default     = null
}

variable "remote_tfstate_storage_account" {
  type        = string
  description = "The name of the storage account for remote Terraform state"
  default     = null
}

variable "remote_tfstate_container" {
  type        = string
  description = "The name of the container for remote Terraform state"
  default     = "tfstate"
}

variable "remote_tfstate_key" {
  type        = string
  description = "The key for the remote Terraform state file"
  default     = null
}

variable "image_name" {
  type        = string
  description = "The name of the container image to deploy (typically set by GitHub workflow). Can be overridden by setting the image property in the YAML configuration."
}

variable "image_tag" {
  type        = string
  description = "The tag of the container image to deploy (typically set by GitHub workflow). Can be overridden by setting the image property in the YAML configuration."
}

variable "appgw_dns_name" {
  type        = string
  description = "The Public DNS A record of the Application Gateway"
  default     = "appgw01.stratus.hafslund.no"
}

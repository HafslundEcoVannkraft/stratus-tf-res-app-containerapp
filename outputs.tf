
output "id" {
  description = "The ID of the Container App."
  value       = module.containerapp.resource.id
}

output "name" {
  description = "The name of the Container App."
  value       = module.containerapp.resource.name
}

output "custom_domain_verification_id" {
  description = "The ID to be used for domain verification."
  value       = module.containerapp.resource.custom_domain_verification_id
}

output "latest_revision_name" {
  description = "The name of the latest revision of the Container App."
  value       = module.containerapp.resource.latest_revision_name
}

output "latest_revision_fqdn" {
  description = "The FQDN of the latest revision of the Container App."
  value       = module.containerapp.resource.latest_revision_fqdn
}

output "identity" {
  description = "The identity block of the Container App."
  value       = module.containerapp.resource.identity
}

output "ingress_fqdn" {
  description = "The FQDN of the Container App's ingress."
  value       = try(module.containerapp.resource.ingress[0].fqdn, null)
}

output "outbound_ip_addresses" {
  description = "The outbound IP addresses of the Container App."
  value       = module.containerapp.resource.outbound_ip_addresses
}

output "private_dns_cname_record" {
  description = "The private DNS CNAME record created for the Container App."
  value       = azurerm_private_dns_cname_record.app
}

output "public_dns_cname_record" {
  description = "The public DNS CNAME record created for the Container App."
  value       = azurerm_dns_cname_record.app
}

output "container_app_identity" {
  description = "The User Assigned Managed Identity created for the Container App."
  value       = module.container_app_identity_for_registry
}

output "containers" {
  description = "The containers configuration of the Container App, including names and images."
  value = [
    for container in try(module.containerapp.resource.template[0].container, []) : {
      name   = container.name
      image  = container.image
      cpu    = container.cpu
      memory = container.memory
    }
  ]
}

output "container_images" {
  description = "Map of container names to their current images."
  value = {
    for container in try(module.containerapp.resource.template[0].container, []) :
    container.name => container.image
  }
}

output "template" {
  description = "The complete template configuration of the Container App."
  value       = try(module.containerapp.resource.template[0], null)
}

output "app_config" {
  description = "The parsed app.yaml configuration used for this deployment."
  value       = local.app_config
}

output "container_app_environment_id" {
  description = "The ID of the Container App Environment where this app is deployed."
  value       = local.container_app_environment_id
}

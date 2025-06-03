# Create CNAME for the Container App pointing to the managed environment
resource "azurerm_private_dns_cname_record" "app" {
  name                = local.app_config.name
  zone_name           = local.private_dns_zone_name
  resource_group_name = "${var.code_name}-dns-zones-rg-${var.environment}"
  ttl                 = 300

  record = "${local.container_app_environment_name}.${local.private_dns_zone_name}"
}
# Create private dns zone CNAME record for the Container App, pointing to the managed environment
resource "azurerm_private_dns_cname_record" "app" {
  name                = local.app_config.name
  zone_name           = local.private_dns_zone_name
  resource_group_name = "${var.code_name}-dns-zones-rg-${var.environment}"
  ttl                 = 300

  record = "${local.container_app_environment_name}.${local.private_dns_zone_name}"
}

# Create public dns zone CNAME for the Container App, pointing to the public A record for application gateway
resource "azurerm_dns_cname_record" "app" {
  name                = local.app_config.name
  zone_name           = local.public_dns_zone_name
  resource_group_name = "${each.value.codename}-dns-zones-rg-${each.value.env}"
  ttl                 = 300

  record = var.appgw_dns_name
}
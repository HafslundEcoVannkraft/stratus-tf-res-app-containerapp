# Create private dns zone CNAME record for the Container App, pointing to the managed environment
resource "azurerm_private_dns_cname_record" "app" {
  name                = local.app_config.name
  zone_name           = local.private_dns_zone_name
  resource_group_name = "${var.code_name}-dns-zones-rg-${var.environment}"
  ttl                 = 300

  record = "${local.container_app_environment_name}.${local.private_dns_zone_name}"
}

# Create public dns zone CNAME for the Container App, pointing to <app>.<codename>.<env>.waf.stratus.hafslund.no
# This is used for external access to the app via the application gateway.
# The intermediate CNMAE record will be created only if external access is configured in the appgw repo

resource "azurerm_dns_cname_record" "app" {
  count = try(local.app_config.ingress.external_enabled, true) && !contains(keys(try(local.app_config.custom_domains, {})), "domain1") ? 1 : 0

  name                = local.app_config.name
  zone_name           = local.public_dns_zone_name
  resource_group_name = "${var.code_name}-dns-zones-rg-${var.environment}"
  ttl                 = 300

  record = "${local.app_config.name}.${var.code_name}.${var.environment}.waf.stratus.hafslund.no"
}

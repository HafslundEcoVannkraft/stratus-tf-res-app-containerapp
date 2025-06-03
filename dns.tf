# Create CNAME for the Container App pointing to the managed environment
resource "azurerm_private_dns_cname_record" "private" {
  name                = local.app_config.name
  zone_name           = local.private_dns_zone_name
  resource_group_name = "${var.code_name}-dns-zones-rg-${var.environment}"
  ttl                 = 300

  record = ["${local.container_app_environment_name}.${local.private_dns_zone_name}"]
}

# Create CNAME for the Container App pointing to the public CNAME for the container app environment
resource "azurerm_private_dns_cname_record" "public" {
  name                = local.app_config.name
  zone_name           = local.public_dns_zone_name
  resource_group_name = "${var.code_name}-dns-zones-rg-${var.environment}"
  ttl                 = 300

  record = ["appgw01.stratus.hafslund.no"]
}
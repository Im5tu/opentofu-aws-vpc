resource "aws_route53_resolver_firewall_rule_group" "this" {
  count = var.enable_dns_firewall ? 1 : 0

  name = "${var.name}-dns-firewall"
  tags = {
    Name = "${var.name}-dns-firewall"
  }
}

resource "aws_route53_resolver_firewall_domain_list" "verified_domains" {
  count = var.enable_dns_firewall ? 1 : 0

  name    = "${var.name}-verified-domains"
  domains = ["*.amazonaws.com", "ghcr.io", "public.ecr.io"]
  tags = {
    Name = "${var.name}-verified-domains"
  }
}
resource "aws_route53_resolver_firewall_rule" "verified_domains" {
  count = var.enable_dns_firewall ? 1 : 0

  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.verified_domains[0].id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.this[0].id
  name                    = "allow-verified"
  action                  = "ALLOW"
  priority                = 1
}

resource "aws_route53_resolver_firewall_domain_list" "allowed_domains" {
  count = var.enable_dns_firewall ? 1 : 0

  name    = "${var.name}-allowed-domains"
  domains = var.dns_firewall_allowed_domains
  tags = {
    Name = "${var.name}-allowed-domains"
  }
}
resource "aws_route53_resolver_firewall_rule" "allowed_domains" {
  count = var.enable_dns_firewall ? 1 : 0

  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.allowed_domains[0].id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.this[0].id
  name                    = "allow-custom"
  action                  = "ALLOW"
  priority                = 10
}

resource "aws_route53_resolver_firewall_domain_list" "blocked_domains" {
  count = var.enable_dns_firewall ? 1 : 0

  name    = "${var.name}-blocked-domains"
  domains = ["*"]
  tags = {
    Name = "${var.name}-blocked-domains"
  }
}
resource "aws_route53_resolver_firewall_rule" "blocked_domains" {
  count = var.enable_dns_firewall ? 1 : 0

  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.blocked_domains[0].id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.this[0].id
  name                    = "block-all"
  action                  = "BLOCK"
  priority                = 9999 # Lowest priority for the catch-all block
  block_response          = "NXDOMAIN"
}
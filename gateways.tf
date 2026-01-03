resource "aws_internet_gateway" "this" {
  count  = var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.name
  }
}

resource "aws_egress_only_internet_gateway" "this" {
  count  = var.enable_egress_only_internet_gateway && !var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = {
    Name = var.name
  }
}

# Determine which AZs should have NAT gateways based on strategy
locals {
  # For single strategy: use only first AZ with enable_nat_gateway=true
  # For per_az strategy: use all AZs with enable_nat_gateway=true
  nat_enabled_azs = [for subnet in var.public_subnets : subnet.availability_zone if subnet.enable_nat_gateway]

  nat_gateway_azs = var.nat_gateway_strategy == "single" ? (
    length(local.nat_enabled_azs) > 0 ? [local.nat_enabled_azs[0]] : []
  ) : local.nat_enabled_azs
}

resource "aws_eip" "public_nat" {
  for_each = toset(local.nat_gateway_azs)

  domain = "vpc"

  depends_on = [aws_subnet.public]

  tags = {
    Name = "${var.name}-nat-${each.key}"
  }
}

resource "aws_nat_gateway" "public" {
  for_each = toset(local.nat_gateway_azs)

  allocation_id     = aws_eip.public_nat[each.key].id
  subnet_id         = aws_subnet.public[each.key].id
  connectivity_type = "public"

  tags = {
    Name = "${var.name}-nat-${each.key}"
  }
}

# ALB Security Group
resource "aws_security_group" "alb" {
  count = var.enable_alb ? 1 : 0

  name        = "${var.name}-alb"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.this.id

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  count = var.enable_alb ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  description       = "Allow HTTP from anywhere"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count = var.enable_alb ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  description       = "Allow HTTPS from anywhere"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  count = var.enable_alb ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lb" "alb" {
  count              = var.enable_alb ? 1 : 0
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets = [
    for subnet in var.public_subnets :
    aws_subnet.public[subnet.availability_zone].id
    if subnet.enable_alb
  ]

  depends_on = [aws_subnet.public, aws_security_group.alb]
}

# WAF Web ACL
resource "aws_wafv2_web_acl" "alb" {
  count = var.enable_alb && var.enable_waf ? 1 : 0

  name        = "${var.name}-alb-waf"
  description = "WAF Web ACL for ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-alb-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.name}-alb-waf"
  }
}

# WAF Web ACL Association
resource "aws_wafv2_web_acl_association" "alb" {
  count = var.enable_alb && var.enable_waf ? 1 : 0

  resource_arn = aws_lb.alb[0].arn
  web_acl_arn  = aws_wafv2_web_acl.alb[0].arn

  depends_on = [aws_lb.alb, aws_wafv2_web_acl.alb]
}

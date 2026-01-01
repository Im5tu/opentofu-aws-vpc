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

resource "aws_lb" "alb" {
  count              = var.enable_alb ? 1 : 0
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "network"
  subnets = [
    for subnet in var.public_subnets :
    aws_subnet.public[subnet.availability_zone].id
    if subnet.enable_alb
  ]

  depends_on = [aws_subnet.public]
}

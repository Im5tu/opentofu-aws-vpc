resource "aws_network_acl" "this" {
  count  = var.enable_vpc_nacl ? 1 : 0
  vpc_id = aws_vpc.this.id

  # Attach to all public and private subnets
  subnet_ids = concat(
    [for s in aws_subnet.public : s.id],
    [for s in aws_subnet.private : s.id]
  )

  tags = {
    Name = "${var.name}-nacl"
  }
}

# Rule 100: Allow all inbound from VPC CIDR
resource "aws_network_acl_rule" "internal_inbound" {
  count          = var.enable_vpc_nacl ? 1 : 0
  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_vpc.this.cidr_block
}

# Rule 200: Allow all outbound to VPC CIDR
resource "aws_network_acl_rule" "internal_outbound" {
  count          = var.enable_vpc_nacl ? 1 : 0
  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 200
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_vpc.this.cidr_block
}

# Rule 300: Allow inbound ephemeral ports (TCP) for return traffic from internet
resource "aws_network_acl_rule" "ephemeral_inbound_tcp" {
  count          = var.enable_vpc_nacl ? 1 : 0
  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 300
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Rule 301: Allow inbound ephemeral ports (UDP) for return traffic from internet
resource "aws_network_acl_rule" "ephemeral_inbound_udp" {
  count          = var.enable_vpc_nacl ? 1 : 0
  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 301
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Rule 400: Allow outbound HTTP to internet
resource "aws_network_acl_rule" "http_outbound" {
  count          = var.enable_vpc_nacl ? 1 : 0
  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 400
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Rule 401: Allow outbound HTTPS to internet
resource "aws_network_acl_rule" "https_outbound" {
  count          = var.enable_vpc_nacl ? 1 : 0
  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 401
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Rule 402: Allow outbound ephemeral ports (TCP) for responses
resource "aws_network_acl_rule" "ephemeral_outbound_tcp" {
  count          = var.enable_vpc_nacl ? 1 : 0
  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 402
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Rule 403: Allow outbound ephemeral ports (UDP) for responses
resource "aws_network_acl_rule" "ephemeral_outbound_udp" {
  count          = var.enable_vpc_nacl ? 1 : 0
  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 403
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Rules 500+: Additional external ports (inbound) from var.nacl_additional_external_ports
resource "aws_network_acl_rule" "additional_ports_inbound_tcp" {
  for_each = var.enable_vpc_nacl ? toset([for p in var.nacl_additional_external_ports : tostring(p)]) : toset([])

  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 500 + index(var.nacl_additional_external_ports, tonumber(each.value))
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.nacl_additional_ports_cidr
  from_port      = tonumber(each.value)
  to_port        = tonumber(each.value)
}

# Rules 600+: Additional external ports (outbound) from var.nacl_additional_external_ports
resource "aws_network_acl_rule" "additional_ports_outbound_tcp" {
  for_each = var.enable_vpc_nacl ? toset([for p in var.nacl_additional_external_ports : tostring(p)]) : toset([])

  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 600 + index(var.nacl_additional_external_ports, tonumber(each.value))
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.nacl_additional_ports_cidr
  from_port      = tonumber(each.value)
  to_port        = tonumber(each.value)
}

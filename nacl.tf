resource "aws_network_acl" "this" {
  count  = var.enable_vpc_nacl ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.name}-nacl"
  }
}

# Associate NACL with public subnets
resource "aws_network_acl_association" "public" {
  for_each = var.enable_vpc_nacl ? aws_subnet.public : {}

  network_acl_id = aws_network_acl.this[0].id
  subnet_id      = each.value.id
}

# Associate NACL with private subnets
resource "aws_network_acl_association" "private" {
  for_each = var.enable_vpc_nacl ? aws_subnet.private : {}

  network_acl_id = aws_network_acl.this[0].id
  subnet_id      = each.value.id
}

resource "aws_network_acl_rule" "internal_inbound" {
  count          = var.enable_vpc_nacl ? 1 : 0
  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_vpc.this.cidr_block
}

resource "aws_network_acl_rule" "internal_outbound" {
  count          = var.enable_vpc_nacl ? 1 : 0
  network_acl_id = aws_network_acl.this[0].id
  rule_number    = 200
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_vpc.this.cidr_block
}

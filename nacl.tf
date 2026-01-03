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

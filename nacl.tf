resource "aws_network_acl" "this" {
  count  = var.enable_vpc_nacl ? 1 : 0
  vpc_id = aws_vpc.this.id

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

# resource "aws_network_acl_rule" "additional_ports_inbound" {
#   for_each       = var.enable_vpc_nacl ? var.nacl_additional_external_ports : []
#   network_acl_id = aws_network_acl.this[0].id
#   rule_number    = 300 + each.key
#   egress         = false
#   protocol       = "-1"
#   rule_action    = "allow"
#   cidr_block     = var.nacl_additional_ports_cidr
#   from_port      = each.value
#   to_port        = each.value
# }
# resource "aws_network_acl_rule" "additional_ports_outbound" {
#   for_each       = var.enable_vpc_nacl ? var.nacl_additional_external_ports : []
#   network_acl_id = aws_network_acl.this[0].id
#   rule_number    = 400 + each.key
#   egress         = true
#   protocol       = "-1"
#   rule_action    = "allow"
#   cidr_block     = var.nacl_additional_ports_cidr
#   from_port      = each.value
#   to_port        = each.value
# }
# Public Subnets
resource "aws_subnet" "public" {
  for_each = {
    for index, subnet in var.public_subnets :
    subnet.availability_zone => subnet
  }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = merge({
    Name = "${var.name}-public-${each.key}"
  }, each.value.tags)
}

# Public Route Tables
resource "aws_route_table" "public" {
  for_each = aws_subnet.public

  vpc_id = aws_vpc.this.id

  tags = merge({
    Name = "${var.name}-rt-public-${each.key}"
  }, each.value.tags)
}

# Public Route: Internet Gateway or Egress-Only Internet Gateway
resource "aws_route" "public_internet" {
  for_each = var.enable_internet_gateway ? aws_route_table.public : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.enable_internet_gateway ? (length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null) : null
}

# Public Route Table Association
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[each.key].id
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each = {
    for index, subnet in var.private_subnets :
    subnet.availability_zone => subnet
  }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = merge({
    Name = "${var.name}-private-${each.key}"
  }, each.value.tags)
}

# Private Route Tables
resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  tags = merge({
    Name = "${var.name}-rt-private-${each.key}"
  }, each.value.tags)
}

# Private Route: NAT Gateway
resource "aws_route" "private_nat" {
  for_each = length(aws_nat_gateway.public) > 0 ? aws_route_table.private : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  # For single NAT strategy: all private subnets use the first (only) NAT gateway
  # For per_az strategy: use NAT gateway in same AZ if available, otherwise fallback to first available
  nat_gateway_id = var.nat_gateway_strategy == "single" ? values(aws_nat_gateway.public)[0].id : (
    contains(keys(aws_nat_gateway.public), each.key) ? aws_nat_gateway.public[each.key].id : values(aws_nat_gateway.public)[0].id
  )
}

# Private Route Table Association
resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the VPC"
}

output "id" {
  value       = aws_vpc.this.id
  description = "The ID of the VPC (deprecated, use vpc_id)"
}

output "cidr" {
  value       = aws_vpc.this.cidr_block
  description = "The CIDR range that's associated with the VPC"
}

# Output for Internet Gateway
output "internet_gateway_id" {
  value       = var.enable_internet_gateway ? aws_internet_gateway.this[0].id : null
  description = "The ID of the Internet Gateway."
}

# Output for Egress-Only Internet Gateway
output "egress_only_internet_gateway_id" {
  value       = var.enable_egress_only_internet_gateway && !var.enable_internet_gateway ? aws_egress_only_internet_gateway.this[0].id : null
  description = "The ID of the Egress-Only Internet Gateway."
}

# Output for NAT Gateway Elastic IPs
output "nat_gateway_eips" {
  value       = { for az, eip in aws_eip.public_nat : az => eip.public_ip }
  description = "The public IPs for the NAT Gateways, mapped by availability zone. Single NAT strategy will have only one entry."
}

# Output for NAT Gateway IDs
output "nat_gateway_ids" {
  value       = { for az, nat in aws_nat_gateway.public : az => nat.id }
  description = "The IDs of the NAT Gateways, mapped by availability zone. Single NAT strategy will have only one entry."
}

# Output for NAT Gateway strategy
output "nat_gateway_strategy" {
  value       = var.nat_gateway_strategy
  description = "The NAT Gateway deployment strategy used (single or per_az)."
}

# Output for alb ARN
output "alb_arn" {
  value       = var.enable_alb ? aws_lb.alb[0].arn : null
  description = "The ARN of the Application Load Balancer."
}

# Subnet outputs
output "public_subnets" {
  value = [
    for key, subnet in aws_subnet.public :
    {
      availability_zone = subnet.availability_zone
      subnet_id         = subnet.id
      cidr              = subnet.cidr_block
      route_table       = aws_route_table.public[key].id
    }
  ]
}

output "private_subnets" {
  value = [
    for key, subnet in aws_subnet.private :
    {
      availability_zone = subnet.availability_zone
      subnet_id         = subnet.id
      cidr              = subnet.cidr_block
      route_table       = aws_route_table.private[key].id
    }
  ]
}

output "private_subnet_ids" {
  value       = [for subnet in aws_subnet.private : subnet.id]
  description = "List of private subnet IDs"
}

output "public_subnet_ids" {
  value       = [for subnet in aws_subnet.public : subnet.id]
  description = "List of public subnet IDs"
}
# OpenTofu AWS VPC

An OpenTofu module for creating AWS VPCs with public/private subnets, NAT gateways, DNS firewall, and optional ALB.

## Usage

```hcl
module "vpc" {
  source = "git::https://github.com/im5tu/opentofu-aws-vpc.git?ref=b5bf74e81361e18bf3dc4950ffe3f4fbd4c1e463"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  public_subnets = [
    {
      cidr                    = "10.0.1.0/24"
      availability_zone       = "eu-west-2a"
      enable_nat_gateway      = true
      enable_alb              = false
      vpc_interface_endpoints = []
      vpc_gateway_endpoints   = ["s3"]
      tags                    = { Tier = "public" }
    },
    {
      cidr                    = "10.0.2.0/24"
      availability_zone       = "eu-west-2b"
      enable_nat_gateway      = true
      enable_alb              = false
      vpc_interface_endpoints = []
      vpc_gateway_endpoints   = []
      tags                    = { Tier = "public" }
    }
  ]

  private_subnets = [
    {
      cidr              = "10.0.10.0/24"
      availability_zone = "eu-west-2a"
      tags              = { Tier = "private" }
    },
    {
      cidr              = "10.0.11.0/24"
      availability_zone = "eu-west-2b"
      tags              = { Tier = "private" }
    }
  ]

  enable_internet_gateway = true
  nat_gateway_strategy    = "single" # or "per_az" for HA
}
```

## Requirements

| Name | Version |
|------|---------|
| opentofu | >= 1.9 |
| aws | ~> 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the VPC | `string` | n/a | yes |
| cidr | The CIDR block for the VPC | `string` | n/a | yes |
| public_subnets | Public subnet configurations | `list(object)` | n/a | yes |
| private_subnets | Private subnet configurations | `list(object)` | n/a | yes |
| enable_internet_gateway | Enable inbound & outbound internet access | `bool` | `false` | no |
| enable_egress_only_internet_gateway | Enable outbound-only internet access | `bool` | `false` | no |
| enable_alb | Enable Application Load Balancer | `bool` | `false` | no |
| enable_dns_firewall | Enable Route53 Resolver DNS Firewall | `bool` | `false` | no |
| dns_firewall_allowed_domains | Domains allowed through DNS firewall | `list(string)` | `[]` | no |
| enable_vpc_nacl | Enable VPC Network ACL | `bool` | `false` | no |
| nacl_additional_external_ports | Additional ports to allow from external sources | `list(number)` | `[]` | no |
| nacl_additional_ports_cidr | CIDR block for additional NACL ports | `string` | `"10.0.0.0/8"` | no |
| nat_gateway_strategy | NAT Gateway strategy: `single` or `per_az` | `string` | `"per_az"` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| cidr | The CIDR range of the VPC |
| internet_gateway_id | The ID of the Internet Gateway |
| egress_only_internet_gateway_id | The ID of the Egress-Only Internet Gateway |
| nat_gateway_eips | Public IPs for NAT Gateways by AZ |
| nat_gateway_ids | NAT Gateway IDs by AZ |
| nat_gateway_strategy | The NAT Gateway strategy used |
| alb_arn | The ARN of the Application Load Balancer |
| public_subnets | Public subnet details (AZ, ID, CIDR, route table) |
| private_subnets | Private subnet details (AZ, ID, CIDR, route table) |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |

## Features

- **Public/Private Subnets**: Configurable subnets across multiple AZs
- **NAT Gateway**: Single (cost-optimized) or per-AZ (HA) deployment
- **DNS Firewall**: Route53 Resolver firewall with allow/block lists
- **VPC Endpoints**: Interface and gateway endpoints per subnet
- **Network ACLs**: Optional NACL with configurable rules
- **ALB**: Optional Application Load Balancer

## License

MIT License - see [LICENSE](LICENSE) for details.

variable "name" {
  description = "The name of the vpc"
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "The cidr variable must be a valid CIDR block."
  }
}

variable "public_subnets" {
  description = "Describes the subnet configuration that we want"
  type = list(object({
    cidr                    = string
    availability_zone       = string
    enable_nat_gateway      = bool
    enable_alb              = bool
    vpc_interface_endpoints = list(string)
    vpc_gateway_endpoints   = list(string)
    tags                    = map(string)
  }))
}

variable "private_subnets" {
  description = "Describes the subnet configuration that we want"
  type = list(object({
    cidr              = string
    availability_zone = string
    tags              = map(string)
  }))
}

variable "enable_internet_gateway" {
  description = "Determines whether or not to enable inbound & outbound internet access"
  type        = bool
  default     = false
}

variable "enable_egress_only_internet_gateway" {
  description = "Determines whether or not to enable outbound internet access"
  type        = bool
  default     = false
}

variable "enable_alb" {
  description = "Determines whether or not to enable the alb"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Determines whether or not to enable WAF for the ALB"
  type        = bool
  default     = false
}

variable "enable_dns_firewall" {
  description = "Determines whether or not the DNS firewall is created"
  type        = bool
  default     = false
}

variable "dns_firewall_allowed_domains" {
  description = "The list of domains that are allowed to be resolved within the vpc"
  type        = list(string)
  default     = []
}

variable "enable_vpc_nacl" {
  description = "Enable or disable the creation of VPC NACL. This needs work to ensure secure comms with VPC Peers"
  type        = bool
  default     = false
}

variable "nacl_additional_external_ports" {
  description = "List of additional ports to allow from external sources"
  type        = list(number)
  default     = []
}

variable "nacl_additional_ports_cidr" {
  description = "CIDR block for additional ports in the NACL rules. Default: 10.0.0.0/8"
  type        = string
  default     = "10.0.0.0/8"
}

variable "nat_gateway_strategy" {
  description = "NAT Gateway deployment strategy: 'single' for one NAT GW (cost-optimized) or 'per_az' for high availability"
  type        = string
  default     = "per_az"

  validation {
    condition     = contains(["single", "per_az"], var.nat_gateway_strategy)
    error_message = "nat_gateway_strategy must be either 'single' or 'per_az'."
  }
}

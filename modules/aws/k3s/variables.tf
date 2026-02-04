variable "name" {
  description = "Name prefix for K3s cluster resources"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability zone for resources"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_api_cidrs" {
  description = "CIDR blocks allowed for K8s API access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "expose_http" {
  description = "Expose HTTP port 80"
  type        = bool
  default     = true
}

variable "expose_https" {
  description = "Expose HTTPS port 443"
  type        = bool
  default     = true
}

variable "k3s_version" {
  description = "K3s version to install (e.g., v1.29.0+k3s1 or stable)"
  type        = string
  default     = "stable"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# WireGuard VPN
# ---------------------------------------------------------------------------
variable "vpn_enabled" {
  description = "Enable WireGuard VPN"
  type        = bool
  default     = false
}

variable "vpn_subnet" {
  description = "VPN subnet CIDR"
  type        = string
  default     = "10.10.0.0/24"
}

variable "vpn_port" {
  description = "WireGuard UDP port"
  type        = number
  default     = 51820
}

variable "vpn_clients" {
  description = "Map of VPN client configurations"
  type = map(object({
    ip = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Monitoring Stack
# ---------------------------------------------------------------------------
variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "domain" {
  description = "Root domain for ingress (e.g., example.com)"
  type        = string
  default     = ""
}

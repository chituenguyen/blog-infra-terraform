data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "vpc" {
  source = "../vpc"

  name               = var.name
  cidr               = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = var.availability_zone
  tags               = var.tags
}

locals {
  # When VPN is enabled, restrict SSH/API to VPN subnet only
  ssh_cidrs = var.vpn_enabled ? [var.vpn_subnet] : var.allowed_ssh_cidrs
  api_cidrs = var.vpn_enabled ? [var.vpn_subnet] : var.allowed_api_cidrs

  ingress_rules = merge(
    {
      ssh = {
        description = "SSH access"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = local.ssh_cidrs
      }
      k8s_api = {
        description = "Kubernetes API"
        from_port   = 6443
        to_port     = 6443
        protocol    = "tcp"
        cidr_blocks = local.api_cidrs
      }
    },
    var.vpn_enabled ? {
      wireguard = {
        description = "WireGuard VPN"
        from_port   = var.vpn_port
        to_port     = var.vpn_port
        protocol    = "udp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    } : {},
    var.expose_http ? {
      http = {
        description = "HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    } : {},
    var.expose_https ? {
      https = {
        description = "HTTPS"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    } : {}
  )
}

module "security_group" {
  source = "../security-group"

  name          = "${var.name}-sg"
  description   = "Security group for K3s cluster"
  vpc_id        = module.vpc.vpc_id
  ingress_rules = local.ingress_rules
  tags          = var.tags
}

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key"
  public_key = var.ssh_public_key

  tags = var.tags
}

resource "aws_eip" "this" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-eip"
  })
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  subnet_id              = module.vpc.public_subnet_id
  vpc_security_group_ids = [module.security_group.security_group_id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    k3s_version      = var.k3s_version
    public_ip        = aws_eip.this.public_ip
    node_name        = var.name
    vpn_enabled      = var.vpn_enabled
    vpn_subnet       = var.vpn_subnet
    vpn_port         = var.vpn_port
    vpn_clients      = var.vpn_clients
    grafana_password = var.grafana_admin_password
    domain           = var.domain
  })

  tags = merge(var.tags, {
    Name = "${var.name}-server"
  })

  depends_on = [aws_eip.this]
}

resource "aws_eip_association" "this" {
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this.id
}

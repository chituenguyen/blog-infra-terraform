terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_security_group" "efs" {
  name        = "${var.name}-efs-sg"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-efs-sg"
  })
}

resource "aws_security_group_rule" "efs_ingress" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.efs.id
  description              = "NFS from allowed security groups"
}

resource "aws_efs_file_system" "this" {
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  encrypted        = var.encrypted

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_efs_mount_target" "this" {
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.efs.id]
}

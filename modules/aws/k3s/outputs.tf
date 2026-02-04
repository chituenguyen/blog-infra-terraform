output "public_ip" {
  description = "Public IP of the K3s server"
  value       = aws_eip.this.public_ip
}

output "private_ip" {
  description = "Private IP of the K3s server"
  value       = aws_instance.this.private_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = var.vpn_enabled ? "ssh -i ~/.ssh/your-key ubuntu@10.10.0.1 (via VPN)" : "ssh -i ~/.ssh/your-key ubuntu@${aws_eip.this.public_ip}"
}

output "kubeconfig_command" {
  description = "Command to retrieve kubeconfig"
  value       = var.vpn_enabled ? "scp -i ~/.ssh/your-key ubuntu@10.10.0.1:/home/ubuntu/.kube/config ~/.kube/k3s-config (via VPN)" : "scp -i ~/.ssh/your-key ubuntu@${aws_eip.this.public_ip}:/home/ubuntu/.kube/config ~/.kube/k3s-config"
}

output "vpn_enabled" {
  description = "Whether VPN is enabled"
  value       = var.vpn_enabled
}

output "vpn_endpoint" {
  description = "WireGuard VPN endpoint"
  value       = var.vpn_enabled ? "${aws_eip.this.public_ip}:${var.vpn_port}" : null
}

output "vpn_server_ip" {
  description = "VPN server internal IP"
  value       = var.vpn_enabled ? "10.10.0.1" : null
}

output "vpn_client_config_command" {
  description = "Command to retrieve VPN client configs"
  value       = var.vpn_enabled ? "ssh -i ~/.ssh/your-key ubuntu@${aws_eip.this.public_ip} 'cat /home/ubuntu/vpn-clients/<username>.conf'" : null
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = module.vpc.public_subnet_id
}

output "security_group_id" {
  description = "Security group ID"
  value       = module.security_group.security_group_id
}

output "vpn_subnet" {
  description = "VPN subnet CIDR"
  value       = var.vpn_enabled ? var.vpn_subnet : null
}

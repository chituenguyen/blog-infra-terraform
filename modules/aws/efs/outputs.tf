output "file_system_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.this.id
}

output "dns_name" {
  description = "EFS DNS name for mounting"
  value       = aws_efs_file_system.this.dns_name
}

output "mount_target_ip" {
  description = "Mount target IP address"
  value       = aws_efs_mount_target.this.ip_address
}

output "security_group_id" {
  description = "EFS security group ID"
  value       = aws_security_group.efs.id
}

output "mount_command" {
  description = "Command to mount EFS"
  value       = "sudo mount -t nfs4 -o nfsvers=4.1 ${aws_efs_file_system.this.dns_name}:/ /mnt/efs"
}

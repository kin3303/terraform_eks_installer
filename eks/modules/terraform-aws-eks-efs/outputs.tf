output "eks_efs" {
  value = {
    efs_file_system_id       = aws_efs_file_system.efs_file_system.id
    efs_file_system_dns_name = aws_efs_file_system.efs_file_system.dns_name
  }
}

output "eks_efs_mount_target" {
  value = {
    efs_mount_target_id = [for mt in aws_efs_mount_target.efs_mount_target : mt.id]
    efs_mount_target_dns_name = [for mt in aws_efs_mount_target.efs_mount_target : mt.mount_target_dns_name]
    efs_mount_target_availability_zone_name = [for mt in aws_efs_mount_target.efs_mount_target : mt.availability_zone_name]
  }
}

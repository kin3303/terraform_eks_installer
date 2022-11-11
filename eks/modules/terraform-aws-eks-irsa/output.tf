output "iam_role_name" {
  description = "IAM Role name"
  value       = aws_iam_role.this.name
}

output "iam_role_arn" {
  description = "IAM Role ARN"
  value       = aws_iam_role.this.arn
}
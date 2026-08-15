output "asg_name" { value = aws_autoscaling_group.app.name }
output "ec2_role_arn" { value = aws_iam_role.ec2.arn }

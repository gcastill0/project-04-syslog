output "ssh_access" {
  value     = "ssh -i ${var.prefix}-ssh-key.pem ubuntu@${aws_instance.app.public_ip}"
}

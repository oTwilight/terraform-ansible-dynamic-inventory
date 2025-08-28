output "instance_public_ips" {
  value = { for os, instance in aws_instance.ec2_instances : os => instance.public_ip }
}
# Output the private key file path
output "private_key_file" {
  value       = local_file.private_key.filename
  description = "Path to the generated private key file"
}
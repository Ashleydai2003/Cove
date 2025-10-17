# Outputs for the Socket.io server
output "socket_server_instance_id" {
  description = "The ID of the Socket.io server EC2 instance"
  value       = aws_instance.socket_server.id
}

output "socket_server_public_ip" {
  description = "The public IP address of the Socket.io server"
  value       = aws_eip.socket_server.public_ip
}

output "socket_server_private_ip" {
  description = "The private IP address of the Socket.io server"
  value       = aws_instance.socket_server.private_ip
}

output "socket_server_health_url" {
  description = "The health check URL for the Socket.io server"
  value       = "http://${aws_eip.socket_server.public_ip}:3001/health"
}

output "socket_server_ws_url" {
  description = "The WebSocket URL for the Socket.io server"
  value       = "ws://${aws_eip.socket_server.public_ip}:3001"
}

output "vendor_images_bucket_name" {
  description = "Name of the S3 bucket for vendor images"
  value       = aws_s3_bucket.vendor_images.bucket
} 
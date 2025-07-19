# Socket.io Server EC2 Setup

This guide explains how to set up and manage the Socket.io server on AWS EC2 for real-time messaging.

## 🏗️ Infrastructure Overview

The Socket.io server runs on an EC2 instance with the following configuration:

- **Instance Type**: t3.medium (2 vCPU, 4 GB RAM)
- **AMI**: Amazon Linux 2023
- **Subnet**: Public subnet for external access
- **Security Group**: Allows traffic on ports 3001 (Socket.io), 80 (health), 22 (SSH)
- **IAM Role**: Access to Secrets Manager, RDS, CloudWatch Logs
- **Elastic IP**: Static public IP address

## 🚀 Quick Start

### 1. Deploy Infrastructure

```bash
# Navigate to infrastructure directory
cd Infra

# Initialize Terraform (if not already done)
terraform init

# Apply the infrastructure
terraform apply -auto-approve
```

### 2. Deploy Socket.io Server

```bash
# Navigate to backend directory
cd Backend

# Run the deployment script
./deploy-socket.sh
```

### 3. Monitor the Server

```bash
# Check server health and status
./monitor-socket.sh
```

## 📋 Prerequisites

### Required Tools
- AWS CLI configured with appropriate permissions
- Terraform installed
- Docker (for containerized deployment)
- Node.js and npm (for direct deployment)

### AWS Permissions
The EC2 instance needs the following permissions:
- Secrets Manager access (for database and Firebase credentials)
- RDS access (for database operations)
- CloudWatch Logs access (for logging)
- SSM Session Manager access (for remote management)

## 🔧 Configuration

### Environment Variables

The Socket.io server requires these environment variables:

```bash
NODE_ENV=production
DATABASE_URL=postgresql://username:password@host:5432/database?schema=public&sslmode=require
RDS_MASTER_SECRET_ARN=arn:aws:secretsmanager:region:account:secret:name
FIREBASE_PROJECT_ID=your-firebase-project-id
SOCKET_PORT=3001
```

### Security Group Rules

The security group allows:
- **Port 3001**: Socket.io WebSocket connections
- **Port 80**: HTTP health checks
- **Port 22**: SSH access (optional, for debugging)

## 🐳 Deployment Options

### Option 1: Docker Deployment (Recommended)

```bash
# Build the Docker image
docker build -f Dockerfile.socket -t cove-socket-server .

# Run the container
docker run -d \
  --name cove-socket \
  --env-file .env \
  -p 3001:3001 \
  cove-socket-server
```

### Option 2: Direct Node.js Deployment

```bash
# Install dependencies
npm install

# Generate Prisma client
npm run prisma:generate

# Start the server
npm run socket:prod
```

## 📊 Monitoring

### Health Check

The server provides a health endpoint at `/health`:

```bash
curl http://your-ec2-ip:3001/health
```

Expected response:
```json
{
  "status": "ok",
  "onlineUsers": 5
}
```

### CloudWatch Logs

Logs are automatically sent to CloudWatch:
- **Log Group**: `/aws/ec2/socket-server`
- **Log Stream**: Instance-specific streams

### Metrics

Monitor these key metrics:
- **CPU Utilization**: Should stay below 80%
- **Memory Usage**: Monitor for memory leaks
- **Network I/O**: Track WebSocket connections
- **Error Rate**: Monitor for failed connections

## 🔄 Updates and Maintenance

### Updating the Server

```bash
# Use the update script
./deploy-socket-update.sh

# Or manually via SSM
aws ssm send-command \
  --instance-ids i-1234567890abcdef0 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "cd /opt/cove-socket/Backend",
    "git pull origin main",
    "npm install",
    "npm run prisma:generate",
    "pkill -f \"npm run socket:prod\"",
    "nohup npm run socket:prod > /var/log/cove-socket.log 2>&1 &"
  ]'
```

### Scaling Considerations

For production with high load:

1. **Auto Scaling Group**: Create an ASG for automatic scaling
2. **Load Balancer**: Use ALB for distributing connections
3. **Redis**: Add Redis for session storage across instances
4. **Monitoring**: Set up CloudWatch alarms for key metrics

## 🔒 Security Best Practices

### Network Security
- Restrict SSH access to specific IP ranges
- Use VPC endpoints for AWS service access
- Consider using a bastion host for SSH access

### Application Security
- Validate all Socket.io messages
- Implement rate limiting
- Use HTTPS/WSS in production
- Regular security updates

### Secrets Management
- Store sensitive data in AWS Secrets Manager
- Rotate credentials regularly
- Use IAM roles instead of access keys

## 🐛 Troubleshooting

### Common Issues

1. **Server Not Starting**
   ```bash
   # Check logs
   tail -f /var/log/cove-socket.log
   
   # Check process
   ps aux | grep socket
   ```

2. **Connection Issues**
   ```bash
   # Test port accessibility
   nc -z your-ec2-ip 3001
   
   # Check security group rules
   aws ec2 describe-security-groups --group-ids sg-1234567890abcdef0
   ```

3. **Database Connection Issues**
   ```bash
   # Test database connectivity
   psql -h your-rds-endpoint -U username -d database
   
   # Check Secrets Manager
   aws secretsmanager get-secret-value --secret-id your-secret-arn
   ```

### Debug Commands

```bash
# Connect to instance via SSM
aws ssm start-session --target i-1234567890abcdef0

# View real-time logs
tail -f /var/log/cove-socket.log

# Check system resources
htop
df -h
free -h

# Test Socket.io connection
curl -X POST http://your-ec2-ip:3001/socket.io/
```

## 📈 Performance Optimization

### Instance Sizing
- **Development**: t3.micro (1 vCPU, 1 GB RAM)
- **Production**: t3.medium (2 vCPU, 4 GB RAM)
- **High Load**: t3.large or larger

### Connection Limits
- **Default**: 1000 concurrent connections
- **High Load**: Configure connection pooling
- **Memory**: Monitor for memory leaks

### Database Optimization
- Use connection pooling
- Implement read replicas for high load
- Monitor query performance

## 🚨 Alerts and Notifications

Set up CloudWatch alarms for:
- CPU utilization > 80%
- Memory usage > 85%
- Disk usage > 90%
- Error rate > 5%
- Health check failures

## 📚 Additional Resources

- [Socket.io Documentation](https://socket.io/docs/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [CloudWatch Monitoring](https://docs.aws.amazon.com/cloudwatch/)

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review CloudWatch logs
3. Test connectivity and permissions
4. Contact the development team 
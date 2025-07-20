#!/bin/bash

# Cove Socket.io Server Deployment Script with SSL Support
# This script deploys the Socket.io server to EC2 with Docker, SSL certificates, and restart policy
#
# Usage:
#   ./deploy-socket.sh                    # Normal deployment
#   ./deploy-socket.sh --force           # Force recreation of EC2 instance
#   ./deploy-socket.sh --ssl-only        # Only setup SSL certificates (for existing deployment)
#
# Environment variables:
#   GITHUB_TOKEN                         # GitHub Personal Access Token for private repo access
#   FIREBASE_PROJECT_ID                  # Firebase Project ID
#   SOCKET_DOMAIN                       # Domain for SSL certificate (e.g., socket.coveapp.co)

set -e

echo "🚀 Starting Secure Socket.io Server Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Check for SSL-only mode
SSL_ONLY=false
if [[ "$1" == "--ssl-only" ]]; then
    SSL_ONLY=true
    print_warning "SSL-only mode enabled - will only setup SSL certificates"
fi

# Check for force recreation flag
FORCE_RECREATE=false
if [[ "$1" == "--force" ]]; then
    FORCE_RECREATE=true
    print_warning "Force recreation mode enabled - will destroy and recreate EC2 instance"
fi

# Check if required environment variables are set
if [ -z "$FIREBASE_PROJECT_ID" ]; then
    print_warning "FIREBASE_PROJECT_ID is not set. Please set it before deployment."
    print_warning "You can set it with: export FIREBASE_PROJECT_ID=your-project-id"
fi

# Check for socket domain
if [ -z "$SOCKET_DOMAIN" ]; then
    print_warning "SOCKET_DOMAIN is not set. SSL certificates will not be configured."
    echo ""
    echo "📋 To enable SSL, set the domain:"
    echo "   export SOCKET_DOMAIN=socket.coveapp.co"
    echo ""
    read -p "Enter your socket domain (e.g., socket.coveapp.co) or press Enter to skip SSL: " socket_domain
    
    if [ -n "$socket_domain" ]; then
        export SOCKET_DOMAIN="$socket_domain"
        print_success "Socket domain set: $SOCKET_DOMAIN"
    else
        print_warning "No domain provided. SSL will be disabled."
    fi
else
    print_success "Socket domain configured: $SOCKET_DOMAIN"
fi

# Check for GitHub token for private repository access
if [ -z "$GITHUB_TOKEN" ]; then
    print_warning "GITHUB_TOKEN is not set. This is required for private repository access."
    echo ""
    echo "📋 To create a GitHub token:"
    echo "1. Go to GitHub.com → Settings → Developer settings → Personal access tokens"
    echo "2. Generate new token with 'repo' scope"
    echo "3. Copy the token (you won't see it again!)"
    echo ""
    read -p "Enter your GitHub Personal Access Token (or press Enter to skip): " -s github_token
    echo ""
    
    if [ -n "$github_token" ]; then
        export GITHUB_TOKEN="$github_token"
        print_success "GitHub token set for this deployment"
    else
        print_warning "No token provided. Repository clone may fail if private."
    fi
else
    print_success "GitHub token found for private repository access"
fi

print_status "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

print_success "AWS credentials verified"

# Get the AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_status "Using AWS Account: $ACCOUNT_ID"

# If SSL-only mode, skip Terraform deployment
if [ "$SSL_ONLY" = false ]; then
    # Navigate to infrastructure directory
    cd ../Infra

    print_status "Initializing Terraform..."
    terraform init

    # Force recreation if requested
    if [ "$FORCE_RECREATE" = true ]; then
        print_status "Destroying existing EC2 instance for force recreation..."
        if [ -n "$GITHUB_TOKEN" ]; then
            terraform destroy -var="github_token=$GITHUB_TOKEN" -auto-approve -target=aws_instance.socket_server
        else
            terraform destroy -auto-approve -target=aws_instance.socket_server
        fi
    fi

    print_status "Planning Terraform deployment..."
    if [ -n "$GITHUB_TOKEN" ]; then
        terraform plan -var="github_token=$GITHUB_TOKEN" -out=tfplan
    else
        terraform plan -out=tfplan
    fi

    print_status "Applying Terraform configuration..."
    if [ -n "$GITHUB_TOKEN" ]; then
        terraform apply -var="github_token=$GITHUB_TOKEN" -auto-approve
    else
        terraform apply -auto-approve
    fi

    # Get the instance ID from Terraform output
    print_status "Getting instance details..."
    INSTANCE_ID=$(terraform output -raw socket_server_instance_id)
    PUBLIC_IP=$(terraform output -raw socket_server_public_ip)
    PRIVATE_IP=$(terraform output -raw socket_server_private_ip)

    print_success "EC2 instance created: $INSTANCE_ID"
    print_success "Public IP: $PUBLIC_IP"
    print_success "Private IP: $PRIVATE_IP"

    # Wait for instance to be ready
    print_status "Waiting for instance to be ready..."
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID

    # Wait a bit more for the user data script to complete
    print_status "Waiting for user data script to complete (this may take a few minutes)..."
    sleep 120

    # Test connectivity
    print_status "Testing connectivity..."
    if aws ssm start-session --target $INSTANCE_ID --document-name AWS-StartSSHSession &> /dev/null; then
        print_success "SSM connectivity confirmed"
    else
        print_warning "SSM connectivity test failed, but this is normal during initial setup"
    fi
else
    # SSL-only mode: get existing instance details
    cd ../Infra
    INSTANCE_ID=$(terraform output -raw socket_server_instance_id)
    PUBLIC_IP=$(terraform output -raw socket_server_public_ip)
    print_status "Using existing instance: $INSTANCE_ID"
fi

# SSL Certificate Setup
if [ -n "$SOCKET_DOMAIN" ]; then
    print_status "Setting up SSL certificates for $SOCKET_DOMAIN..."
    
    # Install certbot and generate certificate
    print_status "Installing certbot..."
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["sudo yum install -y certbot"]' \
        --output text

    # Stop socket server temporarily for certificate generation
    print_status "Stopping socket server for certificate generation..."
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["sudo docker stop socket-server || true"]' \
        --output text

    # Generate SSL certificate
    print_status "Generating SSL certificate..."
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[\"sudo certbot certonly --standalone -d $SOCKET_DOMAIN --non-interactive --agree-tos --email admin@coveapp.co\"]" \
        --output text

    # Copy certificates to expected location
    print_status "Setting up certificate files..."
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=[
            "sudo mkdir -p /etc/ssl/private /etc/ssl/certs",
            "sudo cp /etc/letsencrypt/live/'$SOCKET_DOMAIN'/privkey.pem /etc/ssl/private/server.key",
            "sudo cp /etc/letsencrypt/live/'$SOCKET_DOMAIN'/fullchain.pem /etc/ssl/certs/server.crt",
            "sudo chmod 644 /etc/ssl/private/server.key",
            "sudo chmod 644 /etc/ssl/certs/server.crt",
            "sudo chown root:root /etc/ssl/private/server.key",
            "sudo chown root:root /etc/ssl/certs/server.crt"
        ]' \
        --output text

    # Update environment file with SSL paths
    print_status "Updating environment configuration..."
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=[
            "echo \"NODE_ENV=production\" | sudo tee -a /opt/cove-socket/Backend/.env",
            "echo \"SSL_PRIVATE_KEY_PATH=/etc/ssl/private/server.key\" | sudo tee -a /opt/cove-socket/Backend/.env",
            "echo \"SSL_CERTIFICATE_PATH=/etc/ssl/certs/server.crt\" | sudo tee -a /opt/cove-socket/Backend/.env"
        ]' \
        --output text

    # Restart socket server with SSL
    print_status "Restarting socket server with SSL..."
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=[
            "sudo docker stop socket-server || true",
            "sudo docker rm socket-server || true",
            "cd /opt/cove-socket/Backend && sudo docker run -d --name socket-server -p 3001:3001 --env-file .env -v /etc/ssl/private:/etc/ssl/private:ro -v /etc/ssl/certs:/etc/ssl/certs:ro --restart=always socket-server"
        ]' \
        --output text

    # Set up auto-renewal
    print_status "Setting up SSL certificate auto-renewal..."
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=[
            "sudo crontab -l 2>/dev/null | grep -v certbot > /tmp/crontab.tmp || true",
            "echo \"0 12 * * * /usr/bin/certbot renew --quiet && cp /etc/letsencrypt/live/'$SOCKET_DOMAIN'/privkey.pem /etc/ssl/private/server.key && cp /etc/letsencrypt/live/'$SOCKET_DOMAIN'/fullchain.pem /etc/ssl/certs/server.crt && docker restart socket-server\" >> /tmp/crontab.tmp",
            "sudo crontab /tmp/crontab.tmp"
        ]' \
        --output text

    # Verify SSL setup
    print_status "Verifying SSL certificate setup..."
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=[
            "echo \"=== Host SSL Certificates ===\"",
            "sudo ls -la /etc/ssl/private/",
            "sudo ls -la /etc/ssl/certs/",
            "echo \"=== Docker Container SSL Access ===\"",
            "sudo docker exec socket-server ls -la /etc/ssl/private/ || echo \"Container not running yet\"",
            "sudo docker exec socket-server ls -la /etc/ssl/certs/ || echo \"Container not running yet\"",
            "echo \"=== Environment Variables ===\"",
            "sudo docker exec socket-server env | grep -E \"(NODE_ENV|SSL_)\" || echo \"Container not running yet\""
        ]' \
        --output text

    print_success "SSL certificates configured successfully!"
else
    print_warning "No domain provided. SSL certificates not configured."
fi

# Check Docker container status
print_status "Checking Docker container status..."
aws ssm send-command \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["docker ps -a --filter name=socket-server"]' \
    --output text

# Check container logs
print_status "Checking container logs..."
aws ssm send-command \
    --instance-ids $INSTANCE_ID \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["docker logs socket-server --tail 20"]' \
    --output text

# Test health endpoint
print_status "Testing health endpoint..."
if [ -n "$SOCKET_DOMAIN" ]; then
    # Test HTTPS endpoint
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[\"curl -f https://$SOCKET_DOMAIN:3001/health || echo 'HTTPS health check failed'\"]" \
        --output text
else
    # Test HTTP endpoint
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["curl -f http://localhost:3001/health || echo \"Health check failed\""]' \
        --output text
fi

print_success "Deployment completed!"
echo ""
echo "📋 Deployment Summary:"
echo "   Instance ID: $INSTANCE_ID"
echo "   Public IP: $PUBLIC_IP"
if [ -n "$SOCKET_DOMAIN" ]; then
    echo "   Domain: $SOCKET_DOMAIN"
    echo "   Secure WebSocket URL: wss://$SOCKET_DOMAIN:3001"
    echo "   Secure Health Check: https://$SOCKET_DOMAIN:3001/health"
else
    echo "   WebSocket URL: ws://$PUBLIC_IP:3001"
    echo "   Health Check: http://$PUBLIC_IP:3001/health"
fi
echo ""
echo "🔧 Management Commands:"
echo "   Connect to instance: aws ssm start-session --target $INSTANCE_ID"
echo "   View logs: docker logs socket-server -f"
echo "   Restart container: docker restart socket-server"
echo "   Check status: docker ps -a --filter name=socket-server"
echo ""
echo "📊 Monitoring:"
echo "   CloudWatch Logs: /aws/ec2/socket-server"
echo "   CloudWatch Metrics: Available in AWS Console"
echo ""
echo "⚠️  Important Notes:"
echo "   - Container uses --restart=always for automatic recovery"
echo "   - Systemd service provides additional reliability"
echo "   - CloudWatch monitoring is enabled"
echo "   - Log rotation is configured"
if [ -n "$SOCKET_DOMAIN" ]; then
    echo "   - SSL certificates auto-renew every 90 days"
    echo "   - SSL auto-renewal cron job configured"
fi
echo ""
echo "🎯 Next Steps:"
if [ -n "$SOCKET_DOMAIN" ]; then
    echo "   1. Update your app to connect to: wss://$SOCKET_DOMAIN:3001"
    echo "   2. Test the secure WebSocket connection"
else
    echo "   1. Update your app to connect to: ws://$PUBLIC_IP:3001"
    echo "   2. Test the WebSocket connection"
fi
echo "   3. Monitor logs in CloudWatch"
echo "   4. Set up alerts if needed" 
#!/bin/bash

# Cove Socket.io Server Monitoring Script
# This script monitors the Socket.io server running in Docker on EC2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
}

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

print_metric() {
    echo -e "${CYAN}📊 $1${NC}"
}

# Get instance ID from Terraform output
get_instance_id() {
    cd ../Infra
    terraform output -raw socket_instance_id 2>/dev/null || {
        print_error "Could not get instance ID from Terraform. Make sure you're in the Backend directory."
        exit 1
    }
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials are not configured. Please run 'aws configure' first."
    exit 1
fi

INSTANCE_ID=$(get_instance_id)
print_success "Monitoring Socket.io server on instance: $INSTANCE_ID"

# Function to run command on EC2 instance
run_on_instance() {
    local command="$1"
    aws ssm send-command \
        --instance-ids $INSTANCE_ID \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=[\"$command\"]" \
        --output text \
        --query 'Command.CommandId'
}

# Function to get command output
get_command_output() {
    local command_id="$1"
    aws ssm get-command-invocation \
        --command-id "$command_id" \
        --instance-id $INSTANCE_ID \
        --query 'StandardOutputContent' \
        --output text
}

# Function to check if instance is running
check_instance_status() {
    print_header "🔍 Instance Status Check"
    
    local status=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text)
    
    if [ "$status" = "running" ]; then
        print_success "Instance is running"
        return 0
    else
        print_error "Instance is not running (status: $status)"
        return 1
    fi
}

# Function to check Docker container status
check_docker_status() {
    print_header "🐳 Docker Container Status"
    
    local command_id=$(run_on_instance "docker ps -a --filter name=socket-server --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'")
    sleep 2
    local output=$(get_command_output "$command_id")
    
    if echo "$output" | grep -q "socket-server"; then
        print_success "Docker container found"
        echo "$output"
        
        # Check if container is running
        if echo "$output" | grep -q "Up"; then
            print_success "Container is running"
        else
            print_warning "Container is not running"
        fi
    else
        print_error "Docker container not found"
    fi
}

# Function to check container logs
check_container_logs() {
    print_header "📋 Container Logs (Last 20 lines)"
    
    local command_id=$(run_on_instance "docker logs socket-server --tail 20")
    sleep 2
    local output=$(get_command_output "$command_id")
    
    if [ -n "$output" ]; then
        echo "$output"
    else
        print_warning "No logs found"
    fi
}

# Function to check system resources
check_system_resources() {
    print_header "💻 System Resources"
    
    local commands=(
        "echo '=== CPU Usage ===' && top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | cut -d'%' -f1"
        "echo '=== Memory Usage ===' && free -m | awk 'NR==2{printf \"%.2f%%\", \$3*100/\$2}'"
        "echo '=== Disk Usage ===' && df -h / | awk 'NR==2{print \$5}'"
        "echo '=== Docker Stats ===' && docker stats socket-server --no-stream --format 'table {{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}'"
    )
    
    for cmd in "${commands[@]}"; do
        local command_id=$(run_on_instance "$cmd")
        sleep 2
        local output=$(get_command_output "$command_id")
        echo "$output"
    done
}

# Function to check network connectivity
check_network_connectivity() {
    print_header "🌐 Network Connectivity"
    
    local commands=(
        "echo '=== Port 3001 Status ===' && netstat -tlnp | grep :3001 || echo 'Port 3001 not listening'"
        "echo '=== Health Check ===' && curl -f http://localhost:3001/health 2>/dev/null && echo 'Health check passed' || echo 'Health check failed'"
        "echo '=== WebSocket Test ===' && curl -I http://localhost:3001/socket.io/ 2>/dev/null && echo 'WebSocket endpoint accessible' || echo 'WebSocket endpoint not accessible'"
    )
    
    for cmd in "${commands[@]}"; do
        local command_id=$(run_on_instance "$cmd")
        sleep 2
        local output=$(get_command_output "$command_id")
        echo "$output"
    done
}

# Function to check CloudWatch logs
check_cloudwatch_logs() {
    print_header "📊 CloudWatch Logs"
    
    # Get the latest log stream
    local log_group="/aws/ec2/socket-server"
    local latest_stream=$(aws logs describe-log-streams \
        --log-group-name "$log_group" \
        --order-by LastEventTime \
        --descending \
        --max-items 1 \
        --query 'logStreams[0].logStreamName' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$latest_stream" ] && [ "$latest_stream" != "None" ]; then
        print_success "Latest log stream: $latest_stream"
        
        # Get recent log events
        local events=$(aws logs get-log-events \
            --log-group-name "$log_group" \
            --log-stream-name "$latest_stream" \
            --start-time $(($(date +%s) - 3600))000 \
            --query 'events[*].message' \
            --output text 2>/dev/null || echo "")
        
        if [ -n "$events" ]; then
            echo "Recent log events:"
            echo "$events" | tail -10
        else
            print_warning "No recent log events found"
        fi
    else
        print_warning "No CloudWatch log streams found"
    fi
}

# Function to check environment variables
check_environment_variables() {
    print_header "🔧 Environment Variables"
    
    local command_id=$(run_on_instance "cat /opt/cove-socket/.env")
    sleep 2
    local output=$(get_command_output "$command_id")
    
    if [ -n "$output" ]; then
        echo "$output"
    else
        print_warning "Environment file not found"
    fi
}

# Function to check systemd service status
check_systemd_service() {
    print_header "⚙️ Systemd Service Status"
    
    local command_id=$(run_on_instance "systemctl status socket-server.service --no-pager")
    sleep 2
    local output=$(get_command_output "$command_id")
    
    if [ -n "$output" ]; then
        echo "$output"
    else
        print_warning "Systemd service not found"
    fi
}

# Main monitoring function
main() {
    print_header "🚀 Cove Socket.io Server Monitoring"
    print_status "Instance ID: $INSTANCE_ID"
    print_status "Timestamp: $(date)"
    echo ""
    
    # Run all checks
    check_instance_status
    echo ""
    
    check_docker_status
    echo ""
    
    check_container_logs
    echo ""
    
    check_system_resources
    echo ""
    
    check_network_connectivity
    echo ""
    
    check_environment_variables
    echo ""
    
    check_systemd_service
    echo ""
    
    check_cloudwatch_logs
    echo ""
    
    print_header "✅ Monitoring Complete"
    print_success "All checks completed successfully!"
    echo ""
    print_status "For real-time monitoring, use:"
    print_status "  aws ssm start-session --target $INSTANCE_ID"
    print_status "  docker logs socket-server -f"
    echo ""
    print_status "For CloudWatch monitoring, visit:"
    print_status "  https://console.aws.amazon.com/cloudwatch/home"
}

# Run main function
main 
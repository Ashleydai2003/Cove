# Docker Setup with Restart Policy for Socket.io Server

This document outlines the Docker-based deployment of the Socket.io server with production-grade reliability features.

## 🐳 Docker Configuration

### **Container Setup**
```bash
# Build the Docker image
docker build -f Dockerfile.socket -t socket-server .

# Run with restart policy for production reliability
docker run -d \
  --restart=always \
  -p 3001:3001 \
  --name socket-server \
  --env-file /opt/cove-socket/.env \
  socket-server
```

### **🔁 Restart Policy Benefits**

#### **What `--restart=always` Does:**
- ✅ **Automatic restart on container crash**
- ✅ **Automatic restart on EC2 reboot**
- ✅ **Automatic restart on Docker daemon restart**
- ✅ **Continuous operation without manual intervention**

#### **Restart Scenarios:**
1. **Container crashes** → Automatically restarts
2. **EC2 instance reboots** → Container starts automatically
3. **Docker daemon restarts** → Container restarts
4. **System updates** → Container survives reboots
5. **Memory/CPU issues** → Container recovers automatically

## 🏗️ Production Architecture

### **Multi-Layer Reliability**
```
┌─────────────────────────────────────────────────────────────┐
│                    EC2 Instance                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Systemd Service                       │   │
│  │  (Additional reliability layer)                   │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Docker Container                      │   │
│  │  --restart=always                                 │   │
│  │  --name socket-server                             │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Socket.io Server                      │   │
│  │  Port 3001                                        │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Deployment Features

### **1. Docker Container**
```bash
# Container configuration
docker run -d \
  --restart=always \          # 🔄 Automatic restart
  -p 3001:3001 \             # 🌐 Port mapping
  --name socket-server \      # 🏷️ Container name
  --env-file .env \          # 🔧 Environment variables
  socket-server              # 🐳 Image name
```

### **2. Systemd Service**
```ini
[Unit]
Description=Cove Socket.io Server
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker run -d --restart=always -p 3001:3001 --name socket-server --env-file /opt/cove-socket/.env socket-server
ExecStop=/usr/bin/docker stop socket-server
ExecStopPost=/usr/bin/docker rm socket-server

[Install]
WantedBy=multi-user.target
```

### **3. CloudWatch Monitoring**
```json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/lib/docker/containers/*/socket-server-json.log",
            "log_group_name": "/aws/ec2/socket-server",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
```

## 🔧 Management Commands

### **Container Management**
```bash
# Check container status
docker ps -a --filter name=socket-server

# View logs
docker logs socket-server -f

# Restart container
docker restart socket-server

# Stop container
docker stop socket-server

# Remove container
docker rm socket-server
```

### **Systemd Service Management**
```bash
# Check service status
systemctl status socket-server.service

# Start service
systemctl start socket-server.service

# Stop service
systemctl stop socket-server.service

# Enable service (auto-start on boot)
systemctl enable socket-server.service
```

### **Health Checks**
```bash
# Container health
docker inspect socket-server --format='{{.State.Health.Status}}'

# Application health
curl -f http://localhost:3001/health

# WebSocket endpoint
curl -I http://localhost:3001/socket.io/
```

## 📊 Monitoring & Logging

### **Log Locations**
```bash
# Docker logs
/var/lib/docker/containers/*/socket-server-json.log

# System logs
journalctl -u socket-server.service

# CloudWatch logs
/aws/ec2/socket-server
```

### **Metrics Available**
- ✅ **CPU Usage** (container and host)
- ✅ **Memory Usage** (container and host)
- ✅ **Network I/O** (container)
- ✅ **Disk Usage** (host)
- ✅ **Application Logs** (CloudWatch)
- ✅ **Health Status** (endpoint)

## 🚨 Troubleshooting

### **Common Issues & Solutions**

#### **1. Container Won't Start**
```bash
# Check container logs
docker logs socket-server

# Check environment variables
docker exec socket-server env

# Check port conflicts
netstat -tlnp | grep :3001
```

#### **2. Container Keeps Restarting**
```bash
# Check restart count
docker inspect socket-server --format='{{.RestartCount}}'

# Check exit code
docker inspect socket-server --format='{{.State.ExitCode}}'

# View recent logs
docker logs socket-server --tail 50
```

#### **3. Health Check Fails**
```bash
# Test health endpoint
curl -v http://localhost:3001/health

# Check if port is listening
netstat -tlnp | grep :3001

# Check container status
docker ps -a --filter name=socket-server
```

#### **4. Environment Variables Issues**
```bash
# Check environment file
cat /opt/cove-socket/.env

# Check container environment
docker exec socket-server printenv

# Verify secrets access
docker exec socket-server node -e "
const { SecretsManagerClient } = require('@aws-sdk/client-secrets-manager');
const client = new SecretsManagerClient({ region: 'us-west-1' });
console.log('Secrets Manager client created successfully');
"
```

## 🔄 Restart Policy Options

### **Available Policies**
```bash
--restart=no          # Never restart (default)
--restart=always      # Always restart (our choice)
--restart=unless-stopped  # Restart unless manually stopped
--restart=on-failure  # Restart only on failure
```

### **Why `--restart=always`?**
- ✅ **Maximum uptime** for production
- ✅ **Handles all restart scenarios**
- ✅ **Works with system reboots**
- ✅ **Recovers from crashes**
- ✅ **No manual intervention needed**

## 📈 Performance Benefits

### **Resource Efficiency**
- 🐳 **Container isolation** - No conflicts with other services
- 🔄 **Automatic recovery** - Self-healing system
- 📊 **Resource monitoring** - Built-in metrics
- 🗂️ **Log management** - Centralized logging

### **Operational Benefits**
- 🚀 **Zero-downtime deployments** - Easy container updates
- 🔧 **Easy scaling** - Can run multiple containers
- 📋 **Consistent environment** - Same image everywhere
- 🛡️ **Security** - Isolated from host system

## 🎯 Best Practices

### **1. Resource Limits**
```bash
# Add resource limits for production
docker run -d \
  --restart=always \
  --memory=512m \
  --cpus=1.0 \
  -p 3001:3001 \
  --name socket-server \
  socket-server
```

### **2. Health Checks**
```dockerfile
# Add to Dockerfile.socket
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001/health || exit 1
```

### **3. Log Rotation**
```bash
# Configure log rotation
cat > /etc/logrotate.d/docker-socket << 'EOF'
/var/lib/docker/containers/*/socket-server-json.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 644 root root
}
EOF
```

## 🚀 Deployment Summary

### **What You Get:**
- ✅ **Production-grade reliability** with `--restart=always`
- ✅ **Automatic recovery** from crashes and reboots
- ✅ **Comprehensive monitoring** with CloudWatch
- ✅ **Easy management** with Docker commands
- ✅ **Systemd integration** for additional reliability
- ✅ **Log rotation** and centralized logging
- ✅ **Health checks** and status monitoring

### **Ready for Production:**
The Socket.io server is now configured with enterprise-grade reliability features that ensure maximum uptime and easy management in production environments. 
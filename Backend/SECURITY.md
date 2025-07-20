# Security Configuration for Socket.io Server

## 🔒 Security Issues Fixed

### 1. SSL/TLS Encryption (WSS)
- **Issue**: Socket.io was using unencrypted `ws://` connections
- **Fix**: Implemented SSL support with `wss://` for production in the main `socket-server.ts`
- **Implementation**: 
  - Enhanced `socket-server.ts` with HTTPS support
  - Updated iOS app to use `wss://` URLs in production
  - Added SSL certificate configuration with fallback to HTTP

### 2. Token Security
- **Issue**: Firebase tokens sent over unencrypted WebSocket
- **Fix**: Enhanced token validation and security checks
- **Implementation**:
  - Added token format validation
  - Implemented token age checking
  - Enhanced Firebase token verification with refresh checks
  - Added rate limiting for authentication attempts

### 3. CORS Configuration
- **Issue**: Missing or inadequate CORS configuration
- **Fix**: Comprehensive CORS setup with origin validation
- **Implementation**:
  - Whitelist-based origin validation
  - Support for mobile app origins (`capacitor://`, `ionic://`)
  - Development vs production origin handling
  - Proper credentials handling

## 🛡️ Security Features Implemented

### Authentication & Authorization
- ✅ Firebase token validation with enhanced checks
- ✅ Rate limiting (5 attempts per minute per IP)
- ✅ Token age validation (warns for tokens > 1 hour old)
- ✅ User agent validation (blocks curl requests)

### Network Security
- ✅ SSL/TLS encryption for production (WSS)
- ✅ CORS with whitelist validation
- ✅ Request size limits (1MB max)
- ✅ Connection timeout configuration
- ✅ Transport protocol restrictions

### Application Security
- ✅ Non-root Docker user
- ✅ Security headers configuration
- ✅ Input validation and sanitization
- ✅ Error handling without information disclosure
- ✅ Secure logging practices

## 🔧 Configuration

### Environment Variables

```bash
# Production Security Settings
NODE_ENV=production
ALLOWED_ORIGINS=https://coveapp.co,https://www.coveapp.co,https://api.coveapp.co
SSL_PRIVATE_KEY_PATH=/etc/ssl/private/server.key
SSL_CERTIFICATE_PATH=/etc/ssl/certs/server.crt
MAX_CONNECTION_ATTEMPTS=5
RATE_LIMIT_WINDOW_MS=60000
```

### iOS App Configuration

```swift
// Production uses WSS (secure WebSocket)
static var socketURL: String {
    #if DEBUG
        return "ws://localhost:3001"
    #else
        return "wss://13.52.150.178:3001"
    #endif
}
```

## 🚀 Deployment Steps

### 1. SSL Certificate Setup
```bash
# Generate SSL certificate (for testing)
openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365 -nodes

# Copy to server
scp server.key server.crt ec2-user@13.52.150.178:/etc/ssl/private/
```

### 2. Update Environment
```bash
# Update production environment
cp env.production .env
```

### 3. Deploy Server
```bash
# Build and deploy (same Dockerfile, now with SSL support)
docker build -f Dockerfile.socket -t socket-server .
docker run -d --name socket-server -p 3001:3001 socket-server
```

## 🔍 Security Monitoring

### Health Check Endpoint
```bash
# Test health endpoint
curl http://13.52.150.178:3001/health
```

### Security Logs
```bash
# Monitor security events
docker logs socket-server | grep -E "(Blocked|Rate limit|Authentication)"
```

## ⚠️ Security Best Practices

### Ongoing Maintenance
1. **Regular SSL Certificate Renewal**: Set up automatic renewal
2. **Security Updates**: Keep Node.js and dependencies updated
3. **Monitoring**: Monitor for unusual connection patterns
4. **Backup**: Regular backups of SSL certificates and configurations

### Additional Recommendations
1. **Load Balancer**: Consider using AWS ALB with SSL termination
2. **WAF**: Implement AWS WAF for additional protection
3. **Monitoring**: Set up CloudWatch alarms for security events
4. **Audit**: Regular security audits and penetration testing

## 🐛 Troubleshooting

### Common Issues
1. **SSL Certificate Errors**: Check certificate paths and permissions
2. **CORS Errors**: Verify `ALLOWED_ORIGINS` configuration
3. **Authentication Failures**: Check Firebase token validity
4. **Rate Limiting**: Monitor connection attempt patterns

### Debug Commands
```bash
# Check SSL certificate
openssl s_client -connect 13.52.150.178:3001

# Test WebSocket connection
wscat -c wss://13.52.150.178:3001

# Monitor logs
docker logs -f socket-server
```

## 🔄 Environment-Based Behavior

The server automatically adapts based on the `NODE_ENV` environment variable:

- **Development** (`NODE_ENV=development`): Uses HTTP/WS
- **Production** (`NODE_ENV=production`): Uses HTTPS/WSS with SSL certificates

This single file approach simplifies deployment and maintenance while providing appropriate security for each environment. 
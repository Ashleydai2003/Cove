# Direct Messaging System

This document describes the implementation of the real-time direct messaging system for the Cove app.

## Architecture Overview

The messaging system consists of three main components:

1. **Real-time Socket.io Server** (EC2/Fargate)
2. **Persistence Layer** (Lambda + PostgreSQL)
3. **Push Notifications** (Firebase Cloud Messaging)

## System Components

### 1. Real-time Server (Socket.io)

**Location**: `src/socket-server.ts`
**Deployment**: EC2 or AWS Fargate
**Port**: 3001 (configurable via SOCKET_PORT env var)

**Features**:
- Real-time message delivery
- Typing indicators
- Read receipts
- Online presence tracking
- Automatic FCM notifications for offline users

**Socket Events**:
- `send_message`: Send a new message
- `typing_start`/`typing_stop`: Typing indicators
- `mark_read`: Mark message as read
- `new_message`: Receive new message
- `user_typing`: User typing indicator
- `message_read`: Read receipt
- `user_online`: User online status

### 2. Persistence Layer (Lambda APIs)

**Location**: `src/routes/messaging.ts`

**Endpoints**:
- `POST /create-thread`: Create new conversation thread
- `POST /send-message`: Send message (also triggers Socket.io)
- `GET /threads`: Get user's threads
- `GET /thread-messages`: Get messages with pagination
- `POST /mark-message-read`: Mark message as read
- `POST /update-fcm-token`: Update FCM token for notifications

### 3. Database Schema

**Models**:
- `Thread`: Conversation container
- `ThreadMember`: Many-to-many relationship between users and threads
- `Message`: Individual messages
- `MessageRead`: Read receipts tracking
- `User.fcmToken`: FCM token for push notifications

## Deployment

### Socket.io Server

```bash
# Build Docker image
docker build -f Dockerfile.socket -t cove-socket-server .

# Run locally
docker run -p 3001:3001 --env-file env.development cove-socket-server

# Deploy to ECS/Fargate
# (Use your existing ECS setup)
```

### Lambda Functions

The messaging endpoints are integrated into the existing Lambda function and will be deployed automatically with your current deployment process.

## Client Integration

### Socket.io Connection

```javascript
import { io } from 'socket.io-client';

const socket = io('wss://your-socket-server.com', {
  auth: {
    token: await firebaseUser.getIdToken()
  }
});

// Listen for new messages
socket.on('new_message', (data) => {
  console.log('New message:', data.message);
});

// Send message
socket.emit('send_message', {
  threadId: 'thread123',
  content: 'Hello!'
});

// Typing indicators
socket.emit('typing_start', { threadId: 'thread123' });
socket.emit('typing_stop', { threadId: 'thread123' });

// Mark as read
socket.emit('mark_read', { messageId: 'message123' });
```

### API Integration

```javascript
// Create thread
const response = await fetch('/create-thread', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    participantIds: ['user1', 'user2']
  })
});

// Get threads
const threads = await fetch('/threads', {
  headers: { 'Authorization': `Bearer ${token}` }
});

// Get messages
const messages = await fetch('/thread-messages?threadId=thread123&limit=50', {
  headers: { 'Authorization': `Bearer ${token}` }
});
```

## Environment Variables

### Socket Server
- `SOCKET_PORT`: Port for Socket.io server (default: 3001)
- `DATABASE_URL`: PostgreSQL connection string
- `FIREBASE_PROJECT_ID`: Firebase project ID
- `RDS_MASTER_SECRET_ARN`: AWS Secrets Manager ARN for DB credentials
- `firebaseSDK`: AWS Secrets Manager secret for Firebase credentials

### Lambda Functions
- Same as existing Lambda environment variables
- `USER_IMAGE_BUCKET_NAME`: S3 bucket for user images
- `USER_IMAGE_BUCKET_URL`: S3 bucket URL

## Security

### Authentication
- All Socket.io connections require valid Firebase ID token
- All Lambda endpoints use existing Firebase authentication middleware
- Database queries verify user permissions before operations

### Data Validation
- Input validation on all endpoints
- SQL injection protection via Prisma ORM
- XSS protection via proper content sanitization

## Monitoring & Logging

### Socket Server
- Connection/disconnection logging
- Error logging for failed operations
- Health check endpoint at `/health`

### Lambda Functions
- CloudWatch logs for all operations
- Error tracking and alerting
- Performance monitoring

## Testing

### Test Events
Located in `test-events/`:
- `create-thread.json`
- `send-message.json`
- `get-threads.json`
- `get-thread-messages.json`
- `mark-message-read.json`
- `update-fcm-token.json`

### Manual Testing
```bash
# Test Socket server locally
npm run socket:dev

# Test Lambda functions
npm run dev
```

## Performance Considerations

### Database
- Indexed queries for thread membership
- Pagination for message history
- Efficient read receipt tracking

### Socket.io
- Room-based message broadcasting
- Connection pooling
- Automatic reconnection handling

### FCM
- Batch notifications for efficiency
- Token validation and cleanup
- Fallback handling for failed deliveries

## Future Enhancements

1. **Message Encryption**: End-to-end encryption for messages
2. **File Attachments**: Support for images, documents
3. **Message Reactions**: Like, heart, etc.
4. **Message Editing**: Edit/delete messages
5. **Thread Search**: Search within conversations
6. **Message Threading**: Reply to specific messages
7. **Voice Messages**: Audio message support
8. **Video Calls**: Integration with WebRTC

## Troubleshooting

### Common Issues

1. **Socket Connection Fails**
   - Check Firebase token validity
   - Verify server is running on correct port
   - Check CORS configuration

2. **Messages Not Delivering**
   - Verify user is member of thread
   - Check database connectivity
   - Review FCM token validity

3. **FCM Notifications Not Working**
   - Verify FCM token is updated
   - Check Firebase project configuration
   - Review notification payload format

### Debug Commands

```bash
# Check Socket server health
curl http://localhost:3001/health

# Test database connection
npm run test-database

# View logs
docker logs <container-id>
``` 
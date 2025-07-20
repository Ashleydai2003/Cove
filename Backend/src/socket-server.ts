// /Backend/src/socket-server.ts

import express from 'express';
import { createServer } from 'http';
import { createServer as createHttpsServer } from 'https';
import { Server, Socket } from 'socket.io';
import * as admin from 'firebase-admin';
import { initializeFirebase } from './middleware/firebase';
import { initializeDatabase } from './config/database';
import cors from 'cors';
import fs from 'fs';

// Extend Socket interface to include user property
interface AuthenticatedSocket extends Socket {
  user: admin.auth.DecodedIdToken;
}

const app = express();

// Enhanced CORS configuration
const corsOptions = {
  origin: function (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) {
    // Allow requests with no origin (like mobile apps or Postman)
    if (!origin) return callback(null, true);
    
    const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [
      'https://coveapp.co',
      'https://www.coveapp.co',
      'https://api.coveapp.co',
      'http://localhost:3000', // Development
      'http://localhost:8080', // iOS Simulator
      'capacitor://localhost', // iOS Capacitor
      'ionic://localhost' // Ionic
    ];
    
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      console.warn(`Blocked request from unauthorized origin: ${origin}`);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
};

app.use(cors(corsOptions));

// SSL Configuration
let server;
const isProduction = process.env.NODE_ENV === 'production';

if (isProduction) {
  // Production: Use SSL certificates
  try {
    const privateKey = fs.readFileSync(process.env.SSL_PRIVATE_KEY_PATH || '/etc/ssl/private/server.key', 'utf8');
    const certificate = fs.readFileSync(process.env.SSL_CERTIFICATE_PATH || '/etc/ssl/certs/server.crt', 'utf8');
    
    const credentials = {
      key: privateKey,
      cert: certificate
    };
    
    server = createHttpsServer(credentials, app);
    console.log('🔒 SSL enabled for production');
  } catch (error) {
    console.warn('⚠️  SSL certificates not found, falling back to HTTP');
    server = createServer(app);
  }
} else {
  // Development: Use HTTP
  server = createServer(app);
  console.log('⚠️  Running in development mode (HTTP only)');
}

// Enhanced Socket.io configuration with security improvements
const io = new Server(server, {
  cors: {
    origin: function (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) {
      // Allow requests with no origin (like mobile apps)
      if (!origin) return callback(null, true);
      
      const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [
        'https://coveapp.co',
        'https://www.coveapp.co',
        'https://api.coveapp.co',
        'http://localhost:3000', // Development
        'http://localhost:8080', // iOS Simulator
        'capacitor://localhost', // iOS Capacitor
        'ionic://localhost' // Ionic
      ];
      
      if (allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        console.warn(`Blocked WebSocket connection from unauthorized origin: ${origin}`);
        callback(new Error('Not allowed by CORS'));
      }
    },
    methods: ["GET", "POST"],
    credentials: true
  },
  transports: ['websocket', 'polling'], // Explicitly define transports
  allowEIO3: true, // Enable EIO3 for iOS client compatibility
  pingTimeout: 60000, // 60 seconds
  pingInterval: 25000, // 25 seconds
  maxHttpBufferSize: 1e6, // 1MB max message size
  allowRequest: (req, callback) => {
    // Additional request validation
    const userAgent = req.headers['user-agent'];
    if (userAgent && userAgent.includes('curl')) {
      // Block curl requests to prevent abuse
      return callback(null, false);
    }
    callback(null, true);
  },
  // Additional compatibility settings for older clients
  upgradeTimeout: 10000,
  allowUpgrades: true,
  perMessageDeflate: false // Disable compression for better compatibility
});

// Initialize Firebase
let firebaseInitialized = false;
initializeFirebase().then(() => {
  firebaseInitialized = true;
  console.log('Firebase initialized successfully');
}).catch(error => {
  console.error('Failed to initialize Firebase:', error);
  process.exit(1);
});

// Rate limiting map
const connectionAttempts = new Map<string, { count: number, lastAttempt: number }>();

// Socket authentication middleware with enhanced security
io.use(async (socket, next) => {
  try {
    // Check if Firebase is initialized
    if (!firebaseInitialized) {
      console.error('🔥 Socket auth failed: Firebase not initialized');
      socket.emit("unauthorized", { message: "Server not ready", detail: "Firebase not initialized" });
      return next(new Error('Firebase not initialized yet'));
    }

    // Enhanced rate limiting
    const clientIP = socket.handshake.address;
    const now = Date.now();
    const attempts = connectionAttempts.get(clientIP) || { count: 0, lastAttempt: 0 };
    
    const maxAttempts = parseInt(process.env.MAX_CONNECTION_ATTEMPTS || '5');
    const rateLimitWindow = parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000');
    
    if (now - attempts.lastAttempt < rateLimitWindow) {
      if (attempts.count >= maxAttempts) {
        console.warn(`Rate limit exceeded for IP: ${clientIP}`);
        socket.emit("unauthorized", { message: "Rate limit exceeded", detail: "Too many connection attempts" });
        return next(new Error('Too many connection attempts'));
      }
      attempts.count++;
    } else {
      attempts.count = 1;
    }
    attempts.lastAttempt = now;
    connectionAttempts.set(clientIP, attempts);

    // Check both auth and query for token (iOS uses query, Node.js uses auth)
    const token = socket.handshake.auth.token || socket.handshake.query.token;
    if (!token) {
      console.error('🔥 Socket auth failed: No token provided');
      socket.emit("unauthorized", { message: "Authentication token required", detail: "No token provided" });
      return next(new Error('Authentication token required'));
    }

    // Enhanced token validation
    if (typeof token !== 'string' || token.length < 10) {
      console.error('🔥 Socket auth failed: Invalid token format');
      socket.emit("unauthorized", { message: "Invalid token format", detail: "Token too short or invalid" });
      return next(new Error('Invalid token format'));
    }

    // Verify Firebase token with additional checks
    const decodedToken = await admin.auth().verifyIdToken(token, true); // Force refresh check
    
    // Additional security checks
    if (!decodedToken.uid) {
      console.error('🔥 Socket auth failed: Invalid token - missing UID');
      socket.emit("unauthorized", { message: "Invalid token", detail: "Missing UID" });
      return next(new Error('Invalid token: missing UID'));
    }
    
    if (decodedToken.auth_time && (Date.now() / 1000) - decodedToken.auth_time > 3600) {
      // Token is older than 1 hour, consider refreshing
      console.warn(`Token for user ${decodedToken.uid} is older than 1 hour`);
    }

    (socket as AuthenticatedSocket).user = decodedToken;
    next();
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error('🔥 Socket auth failed:', errorMessage);
    socket.emit("unauthorized", { message: "Authentication failed", detail: errorMessage });
    next(new Error('Authentication failed'));
  }
});

// Store online users
const onlineUsers = new Map<string, string>(); // userId -> socketId

io.on('connection', async (socket) => {
  const authenticatedSocket = socket as AuthenticatedSocket;
  const userId = authenticatedSocket.user.uid;
  console.log(`User ${userId} connected`);
  console.log('Socket handshake query:', socket.handshake.query);
  console.log('Socket handshake auth:', socket.handshake.auth);

  // Add user to online users
  onlineUsers.set(userId, socket.id);

  // Join user to their personal room for notifications
  socket.join(`user:${userId}`);

  // Get user's threads and join them
  try {
    const prisma = await initializeDatabase();
    const userThreads = await prisma.thread.findMany({
      where: {
        members: {
          some: {
            userId: userId
          }
        }
      },
      select: { id: true }
    });

    // Join all user's threads
    userThreads.forEach(thread => {
      socket.join(`thread:${thread.id}`);
    });

    // Broadcast user online status to all threads
    userThreads.forEach(thread => {
      socket.to(`thread:${thread.id}`).emit('user_online', {
        userId: userId,
        threadId: thread.id
      });
    });
  } catch (error) {
    console.error('Error joining user to threads:', error);
  }

  // Handle new message
  socket.on('send_message', async (data) => {
    try {
      const { threadId, content } = data;
      const prisma = await initializeDatabase();

      // Verify user is a member of the thread
      const threadMember = await prisma.threadMember.findUnique({
        where: {
          threadId_userId: {
            threadId,
            userId
          }
        }
      });

      if (!threadMember) {
        socket.emit('error', { message: 'You are not a member of this thread' });
        return;
      }

      // Create message in database
      const message = await prisma.message.create({
        data: {
          threadId,
          senderId: userId,
          content
        },
        include: {
          sender: {
            select: { id: true, name: true }
          }
        }
      });

      // Update thread's last message
      await prisma.thread.update({
        where: { id: threadId },
        data: { lastMessageId: message.id }
      });

      // Broadcast message to thread room
      io.to(`thread:${threadId}`).emit('new_message', {
        message,
        threadId
      });

      // Send FCM notifications to offline users
      const threadMembers = await prisma.threadMember.findMany({
        where: { threadId },
        include: {
          user: {
            select: { id: true, name: true, fcmToken: true }
          }
        }
      });

      const sender = await prisma.user.findUnique({
        where: { id: userId },
        select: { name: true }
      });

      for (const member of threadMembers) {
        if (member.userId !== userId && member.user.fcmToken) {
          // Check if user is online
          const isOnline = onlineUsers.has(member.userId);
          
          if (!isOnline) {
            // Send FCM notification
            try {
              await admin.messaging().sendToDevice(member.user.fcmToken, {
                notification: {
                  title: `New message from ${sender?.name || 'Someone'}`,
                  body: content,
                },
                data: {
                  threadId,
                  messageId: message.id,
                  type: 'new_message'
                },
              });
            } catch (error) {
              console.error('Error sending FCM notification:', error);
            }
          }
        }
      }
    } catch (error) {
      console.error('Error handling send_message:', error);
      socket.emit('error', { message: 'Error sending message' });
    }
  });

  // Handle typing indicator
  socket.on('typing_start', (data) => {
    const { threadId } = data;
    socket.to(`thread:${threadId}`).emit('user_typing', {
      userId: userId,
      threadId: threadId,
      isTyping: true
    });
  });

  socket.on('typing_stop', (data) => {
    const { threadId } = data;
    socket.to(`thread:${threadId}`).emit('user_typing', {
      userId: userId,
      threadId: threadId,
      isTyping: false
    });
  });

  // Handle read receipts
  socket.on('mark_read', async (data) => {
    try {
      const { messageId } = data;
      const prisma = await initializeDatabase();

      // Verify user has access to the message
      const message = await prisma.message.findFirst({
        where: {
          id: messageId,
          thread: {
            members: {
              some: {
                userId: userId
              }
            }
          }
        }
      });

      if (!message) {
        socket.emit('error', { message: 'Message not found or access denied' });
        return;
      }

      // Mark as read
      await prisma.messageRead.upsert({
        where: {
          messageId_userId: {
            messageId,
            userId
          }
        },
        update: {
          readAt: new Date()
        },
        create: {
          messageId,
          userId
        }
      });

      // Broadcast read receipt to thread
      io.to(`thread:${message.threadId}`).emit('message_read', {
        messageId,
        userId,
        threadId: message.threadId
      });
    } catch (error) {
      console.error('Error handling mark_read:', error);
      socket.emit('error', { message: 'Error marking message as read' });
    }
  });

  // Handle disconnect
  socket.on('disconnect', () => {
    console.log(`User ${userId} disconnected`);
    onlineUsers.delete(userId);

    // Broadcast user offline status
    // Note: In a production environment, you'd want to handle this more robustly
    // by tracking which threads the user was in and broadcasting to those specific threads
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    onlineUsers: onlineUsers.size,
    ssl: isProduction,
    timestamp: new Date().toISOString()
  });
});

const PORT = parseInt(process.env.SOCKET_PORT || '3001', 10);

server.listen(PORT, '0.0.0.0', () => {
  const protocol = isProduction ? 'WSS' : 'WS';
  console.log(`🔒 Socket.io server running on port ${PORT} (${protocol})`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
});

export default server; 
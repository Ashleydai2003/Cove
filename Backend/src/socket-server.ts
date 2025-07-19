// /Backend/src/socket-server.ts

import express from 'express';
import { createServer } from 'http';
import { Server } from 'socket.io';
import * as admin from 'firebase-admin';
import { initializeFirebase } from './middleware/firebase';
import { initializeDatabase } from './config/database';
import cors from 'cors';

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Configure this properly for production
    methods: ["GET", "POST"]
  }
});

// Initialize Firebase
initializeFirebase();

// Socket authentication middleware
io.use(async (socket, next) => {
  try {
    const token = socket.handshake.auth.token;
    if (!token) {
      return next(new Error('Authentication token required'));
    }

    // Verify Firebase token
    const decodedToken = await admin.auth().verifyIdToken(token);
    socket.user = decodedToken;
    next();
  } catch (error) {
    console.error('Socket authentication error:', error);
    next(new Error('Authentication failed'));
  }
});

// Store online users
const onlineUsers = new Map<string, string>(); // userId -> socketId

io.on('connection', async (socket) => {
  const userId = socket.user.uid;
  console.log(`User ${userId} connected`);

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
  res.json({ status: 'ok', onlineUsers: onlineUsers.size });
});

const PORT = process.env.SOCKET_PORT || 3001;

server.listen(PORT, () => {
  console.log(`Socket.io server running on port ${PORT}`);
});

export default server; 
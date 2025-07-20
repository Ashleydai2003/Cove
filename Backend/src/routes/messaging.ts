// /Backend/src/routes/messaging.ts

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { initializeFirebase } from '../middleware/firebase';
import * as admin from 'firebase-admin';

// Types for messaging
interface CreateThreadRequest {
  participantIds: string[];
}

interface SendMessageRequest {
  threadId: string;
  content: string;
}

interface MarkReadRequest {
  messageId: string;
}

// Helper function to send FCM notification
async function sendFCMNotification(userId: string, title: string, body: string, data?: any) {
  try {
    const prisma = await initializeDatabase();
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true }
    });

    if (user?.fcmToken) {
      await admin.messaging().sendToDevice(user.fcmToken, {
        notification: {
          title,
          body,
        },
        data: data || {},
      });
    }
  } catch (error) {
    console.error('Error sending FCM notification:', error);
  }
}

// Create a new thread between users
export const handleCreateThread = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for creating threads.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 2: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 3: Parse request body
    const { participantIds }: CreateThreadRequest = JSON.parse(event.body || '{}');
    const currentUserId = authResult.user.uid;

    // Validate input
    if (!participantIds || !Array.isArray(participantIds) || participantIds.length === 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'participantIds array is required' })
      };
    }

    // Ensure current user is included in participants
    const allParticipants = [...new Set([currentUserId, ...participantIds])];

    // Check if thread already exists between these participants
    const existingThread = await prisma.thread.findFirst({
      where: {
        members: {
          every: {
            userId: { in: allParticipants }
          }
        }
      },
      include: {
        members: {
          include: {
            user: {
              select: { id: true, name: true }
            }
          }
        }
      }
    });

    if (existingThread) {
      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'Thread already exists',
          thread: existingThread
        })
      };
    }

    // Create new thread
    const thread = await prisma.thread.create({
      data: {
        members: {
          create: allParticipants.map(userId => ({
            userId
          }))
        }
      },
      include: {
        members: {
          include: {
            user: {
              select: { id: true, name: true }
            }
          }
        }
      }
    });

    return {
      statusCode: 201,
      body: JSON.stringify({
        message: 'Thread created successfully',
        thread
      })
    };
  } catch (error) {
    console.error('Error creating thread:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error creating thread',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// Send a message to a thread
export const handleSendMessage = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for sending messages.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 2: Initialize database and Firebase
    const prisma = await initializeDatabase();
    await initializeFirebase();

    // Step 3: Parse request body
    const { threadId, content }: SendMessageRequest = JSON.parse(event.body || '{}');
    const currentUserId = authResult.user.uid;

    // Validate input
    if (!threadId || !content) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'threadId and content are required' })
      };
    }

    // Verify user is a member of the thread
    const threadMember = await prisma.threadMember.findUnique({
      where: {
        threadId_userId: {
          threadId,
          userId: currentUserId
        }
      }
    });

    if (!threadMember) {
      return {
        statusCode: 403,
        body: JSON.stringify({ message: 'You are not a member of this thread' })
      };
    }

    // Create the message
    const message = await prisma.message.create({
      data: {
        threadId,
        senderId: currentUserId,
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

    // Get thread members for FCM notifications
    const threadMembers = await prisma.threadMember.findMany({
      where: { threadId },
      include: {
        user: {
          select: { id: true, name: true, fcmToken: true }
        }
      }
    });

    // Send FCM notifications to other members
    const sender = await prisma.user.findUnique({
      where: { id: currentUserId },
      select: { name: true }
    });

    for (const member of threadMembers) {
      if (member.userId !== currentUserId && member.user.fcmToken) {
        await sendFCMNotification(
          member.userId,
          `New message from ${sender?.name || 'Someone'}`,
          content,
          {
            threadId,
            messageId: message.id,
            type: 'new_message'
          }
        );
      }
    }

    return {
      statusCode: 201,
      body: JSON.stringify({
        message: 'Message sent successfully',
        messageData: message
      })
    };
  } catch (error) {
    console.error('Error sending message:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error sending message',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// Get all threads for a user
export const handleGetThreads = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is GET
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving threads.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 2: Initialize database connection
    const prisma = await initializeDatabase();

    const currentUserId = authResult.user.uid;

    const threads = await prisma.thread.findMany({
      where: {
        members: {
          some: {
            userId: currentUserId
          }
        }
      },
      include: {
        members: {
          include: {
            user: {
              select: { id: true, name: true }
            }
          }
        },
        lastMessage: {
          include: {
            sender: {
              select: { id: true, name: true }
            }
          }
        },
        _count: {
          select: {
            messages: true
          }
        }
      },
      orderBy: {
        updatedAt: 'desc'
      }
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        threads
      })
    };
  } catch (error) {
    console.error('Error fetching threads:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error fetching threads',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// Get messages for a specific thread with pagination
export const handleGetThreadMessages = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is GET
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving messages.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 2: Initialize database connection
    const prisma = await initializeDatabase();

    const currentUserId = authResult.user.uid;
    const threadId = event.pathParameters?.threadId;
    const limit = parseInt(event.queryStringParameters?.limit || '50');
    const cursor = event.queryStringParameters?.cursor;

    if (!threadId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'threadId is required' })
      };
    }

    // Verify user is a member of the thread
    const threadMember = await prisma.threadMember.findUnique({
      where: {
        threadId_userId: {
          threadId,
          userId: currentUserId
        }
      }
    });

    if (!threadMember) {
      return {
        statusCode: 403,
        body: JSON.stringify({ message: 'You are not a member of this thread' })
      };
    }

    // Get messages with pagination
    const messages = await prisma.message.findMany({
      where: { threadId },
      include: {
        sender: {
          select: { id: true, name: true }
        },
        reads: {
          include: {
            user: {
              select: { id: true, name: true }
            }
          }
        }
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      ...(cursor && { cursor: { id: cursor } })
    });

    // Get next cursor
    const nextCursor = messages.length === limit ? messages[messages.length - 1]?.id : null;

    return {
      statusCode: 200,
      body: JSON.stringify({
        messages: messages.reverse(), // Reverse to get chronological order
        nextCursor
      })
    };
  } catch (error) {
    console.error('Error fetching messages:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error fetching messages',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// Mark a message as read
export const handleMarkMessageRead = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for marking messages as read.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 2: Initialize database connection
    const prisma = await initializeDatabase();

    const currentUserId = authResult.user.uid;
    const messageId = event.pathParameters?.messageId;

    if (!messageId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'messageId is required' })
      };
    }

    // Verify the message exists and user has access to it
    const message = await prisma.message.findFirst({
      where: {
        id: messageId,
        thread: {
          members: {
            some: {
              userId: currentUserId
            }
          }
        }
      }
    });

    if (!message) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Message not found or access denied' })
      };
    }

    // Mark as read (upsert to avoid duplicates)
    await prisma.messageRead.upsert({
      where: {
        messageId_userId: {
          messageId,
          userId: currentUserId
        }
      },
      update: {
        readAt: new Date()
      },
      create: {
        messageId,
        userId: currentUserId
      }
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Message marked as read'
      })
    };
  } catch (error) {
    console.error('Error marking message as read:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error marking message as read',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// Update user's FCM token
export const handleUpdateFCMToken = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for updating FCM token.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 2: Initialize database connection
    const prisma = await initializeDatabase();

    const currentUserId = authResult.user.uid;
    const { fcmToken } = JSON.parse(event.body || '{}');

    if (!fcmToken) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'fcmToken is required' })
      };
    }

    await prisma.user.update({
      where: { id: currentUserId },
      data: { fcmToken }
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'FCM token updated successfully'
      })
    };
  } catch (error) {
    console.error('Error updating FCM token:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error updating FCM token',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
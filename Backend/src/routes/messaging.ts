import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';

// Messaging endpoints - placeholder for future implementation
// These will be implemented when messaging is ready

export const handleCreateThread = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
      return {
    statusCode: 501,
        body: JSON.stringify({
      message: 'Messaging not yet implemented'
        })
      };
};

export const handleSendMessage = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
      return {
    statusCode: 501,
        body: JSON.stringify({
      message: 'Messaging not yet implemented'
      })
    };
};

export const handleGetThreads = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
      return {
    statusCode: 501,
        body: JSON.stringify({
      message: 'Messaging not yet implemented'
      })
    };
};

export const handleGetThreadMessages = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
      return {
    statusCode: 501,
        body: JSON.stringify({
      message: 'Messaging not yet implemented'
    })
  };
};

export const handleMarkMessageRead = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
      return {
    statusCode: 501,
        body: JSON.stringify({
      message: 'Messaging not yet implemented'
      })
    };
};

export const handleUpdateFCMToken = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod && event.httpMethod !== 'POST') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method Not Allowed' }) };
    }

    // Authenticate user via Firebase ID token
    const authed = await authMiddleware(event);
    if ('statusCode' in authed) {
      return authed;
    }

    const prisma = await initializeDatabase();

    const body = authed.body ? JSON.parse(authed.body) : {};
    const rawToken = body.fcmToken;

    // Validate
    if (rawToken !== null && rawToken !== undefined && typeof rawToken !== 'string') {
      return { statusCode: 400, body: JSON.stringify({ message: 'Invalid fcmToken type' }) };
    }

    const fcmToken: string | null = (typeof rawToken === 'string') ? rawToken.trim() : null;
    if (fcmToken && (fcmToken.length < 10 || fcmToken.length > 4096)) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Invalid fcmToken length' }) };
    }

    // Persist to the authenticated user
    await prisma.user.update({
      where: { id: authed.user.uid },
      data: { fcmToken: fcmToken && fcmToken.length > 0 ? fcmToken : null },
    });

    return {
      statusCode: 200,
      body: JSON.stringify({ success: true })
    };
  } catch (error) {
    console.error('Error updating FCM token:', error);
    return { statusCode: 500, body: JSON.stringify({ message: 'Internal Server Error' }) };
  }
}; 
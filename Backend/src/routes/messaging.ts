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
    if (event.httpMethod !== 'POST') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed. Only POST.' }) };
    }
    // Quietly ignore pre-auth calls (old clients/simulators) to avoid noisy logs
    const authHeader = event.headers?.authorization || event.headers?.Authorization;
    if (!authHeader) {
      return { statusCode: 204, body: '' };
    }

    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) return authResult;

    if (!event.body) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Request body is required' }) };
    }
    const { fcmToken } = JSON.parse(event.body);
    if (typeof fcmToken !== 'string' || fcmToken.length < 20) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Invalid fcmToken' }) };
    }

    const prisma = await initializeDatabase();
    await prisma.user.update({ where: { id: authResult.user.uid }, data: { fcmToken } });

    return { statusCode: 200, body: JSON.stringify({ message: 'FCM token updated' }) };
  } catch (err) {
    console.error('Update FCM token error:', err);
    return { statusCode: 500, body: JSON.stringify({ message: 'Server error' }) };
  }
}; 
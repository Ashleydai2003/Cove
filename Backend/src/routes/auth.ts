// Auth validation route for checking if a user is authenticated

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';

export const handleAuthValidate = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is GET
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for auth validation.'
        })
      };
    }

    // Authenticate the request
    const authResult = await authMiddleware(event);
    
    // Check if auth failed (returns 401 response)
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Auth successful - return basic user info
    return {
      statusCode: 200,
      body: JSON.stringify({
        isAuthenticated: true,
        user: {
          id: authResult.user.uid,
          email: authResult.user.email,
          phone: authResult.user.phone_number
        }
      })
    };
  } catch (error) {
    console.error('Auth validation error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing auth validation request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
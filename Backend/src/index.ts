// /Backend/src/index.ts

// This file is supposed to be the entry point for the backend application.
// Currently, it is just a placeholder hello world function

import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { authMiddleware } from './middleware/auth';
import { handleProfile, handleLogin, handleTestDatabase, handleTestS3 } from './routes';

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  console.log('=== Lambda Function Start ===');
  console.log('Path:', event.path);
  
  try {
    // Route handling based on path
    switch (event.path) {
      case '/profile':
        return handleProfile(event);
      case '/login':
        return handleLogin(event);
      case '/test-database':
        return handleTestDatabase(event);
      case '/test-s3':
        return handleTestS3(event);
      default:
        return {
          statusCode: 404,
          body: JSON.stringify({ message: 'Not Found' })
        };
    }
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : 'Unknown error');
    console.error('Stack:', error instanceof Error ? error.stack : 'No stack trace');
    
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

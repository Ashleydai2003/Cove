// /Backend/src/index.ts

// This file is supposed to be the entry point for the backend application.
// Currently, it is just a placeholder hello world function

import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { handleProfile, handleLogin, handleTestDatabase, handleTestS3, handleOnboard, handleUserImage, handleContacts, handleCreateEvent, handleCreateCove, handleSendFriendRequest, handleResolveFriendRequest } from './routes';

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
      case '/onboard':
        return handleOnboard(event);
      case '/userImage':
        return handleUserImage(event);
      case '/contacts':
        return handleContacts(event);
      case '/create-event':
        return handleCreateEvent(event);
      case '/create-cove':
        return handleCreateCove(event);
      case '/send-friend-request':
        return handleSendFriendRequest(event);
      case '/resolve-friend-request':
        return handleResolveFriendRequest(event);
      default:
        // Handle common web standard files
        switch (event.path) {
          case '/robots.txt':
            console.log('Robots.txt request');
            return {
              statusCode: 200,
              headers: {
                'Content-Type': 'text/plain'
              },
              body: 'User-agent: *\nDisallow: /'
            };
          case '/favicon.ico':
          case '/apple-touch-icon-precomposed.png':
          case '/apple-touch-icon.png':
            console.log('Favicon/icon request:', event.path);
            return {
              statusCode: 204, // No content
              body: ''
            };
        }

        // Check if the request is for a static asset
        if (event.path && event.path.match(/\.(png|jpg|jpeg|gif|ico|svg)$/i)) {
          console.log('Static asset request:', event.path);
          return {
            statusCode: 404,
            body: JSON.stringify({ 
              message: 'Static asset not found',
              path: event.path
            })
          };
        }
        
        return {
          statusCode: 404,
          body: JSON.stringify({ 
            message: 'Not Found',
            path: event.path
          })
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

// /Backend/src/index.ts

// This file is supposed to be the entry point for the backend application.
// Currently, it is just a placeholder hello world function

import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import {
  handleProfile,
  handleEditProfile,
  handleLogin,
  handleTestDatabase,
  handleTestS3,
  handleOnboard,
  handleUserImage,
  handleUserImageUpdate,
  handleContacts,
  handleCreateEvent,
  handleCreateCove,
  handleSendFriendRequest,
  handleResolveFriendRequest,
  handleGetCoveEvents,
  handleGetUpcomingEvents,
  handleGetFriends,
  handleGetFriendRequests,
  handleGetCove,
  handleGetCoveMembers,
  handleDeleteUser,
  handleDeleteEvent,
  handleGetEvent,
  handleGetUserCoves,
  handleUpdateEventRSVP,
  handleGetRecommendedFriends,
  handleJoinCove,
  handleGetCalendarEvents,
  handleSendInvite,
  handleGetInvites,
  handleOpenInvite,
  handleRejectInvite,
  handleCreateThread,
  handleSendMessage,
  handleGetThreads,
  handleGetThreadMessages,
  handleMarkMessageRead,
  handleUpdateFCMToken,
} from './routes';

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
      case '/userImageUpdate':
        return handleUserImageUpdate(event);
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
      case '/cove-events':
        return handleGetCoveEvents(event);
      case '/upcoming-events':
        return handleGetUpcomingEvents(event);
      case '/friends':
        return handleGetFriends(event);
      case '/friend-requests':
        return handleGetFriendRequests(event);
      case '/cove':
        return handleGetCove(event);
      case '/cove-members':
        return handleGetCoveMembers(event);
      case '/edit-profile':
        return handleEditProfile(event);
      case '/delete-user':
        return handleDeleteUser(event);
      case '/delete-event':
        return handleDeleteEvent(event);
      case '/event':
        return handleGetEvent(event);
      case '/user-coves':
        return handleGetUserCoves(event);
      case '/update-event-rsvp':
        return handleUpdateEventRSVP(event);
      case '/recommended-friends':
        return handleGetRecommendedFriends(event);
      case '/join-cove':
        return handleJoinCove(event);
      case '/calendar-events':
        return handleGetCalendarEvents(event);
      case '/send-invite':
        return handleSendInvite(event);
      case '/invites':
        return handleGetInvites(event);
      case '/open-invite':
        return handleOpenInvite(event);
      case '/reject-invite':
        return handleRejectInvite(event);
      // Messaging routes
      case '/create-thread':
        return handleCreateThread(event);
      case '/send-message':
        return handleSendMessage(event);
      case '/threads':
        return handleGetThreads(event);
      case '/thread-messages':
        return handleGetThreadMessages(event);
      case '/mark-message-read':
        return handleMarkMessageRead(event);
      case '/update-fcm-token':
        return handleUpdateFCMToken(event);
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

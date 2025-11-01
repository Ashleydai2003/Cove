// /Backend/src/index.ts

// Entry point for the backend application Lambda handler

import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { addCorsHeaders, handleCorsPreflightRequest } from './utils/cors';
import {
  handleProfile,
  handleEditProfile,
  handleLogin,
  handleAuthValidate,
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
  handleGetFriends,
  handleGetFriendRequests,
  handleGetCove,
  handleGetCoveMembers,
  handleDeleteUser,
  handleDeleteEvent,
  handleDeleteCove,
  handleGetEvent,
  handleGetUserCoves,
  handleUpdateEventRSVP,
  handleRemoveEventRSVP,
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
  handleCreatePost,
  handleGetCovePosts,
  handleGetPost,
  handleTogglePostLike,
  handleGetFeed,
  handleGetEventMembers,
  handleGetPendingMembers,
  handleApproveDeclineRSVP,
  handleGetUniversities,
  handleSMSWebhook,
  // Vendor routes
  handleVendorLogin,
  handleValidateVendorCode,
  handleCreateVendorOrganization,
  handleVendorOnboard,
  handleJoinVendorOrganization,
  handleGetVendorProfile,
  handleRotateVendorCode,
  handleGetVendorMembers,
  handleCreateVendorEvent,
  handleGetVendorEvents,
  handleVendorImageUpload,
  handleVendorImageUpdate,
  // AI Matching routes
  handleSurveySubmit,
  handleGetSurvey,
  handleCreateIntention,
  handleGetIntentionStatus,
  handleDeleteIntention,
  handleGetCurrentMatch,
  handleAcceptMatch,
  handleDeclineMatch,
  handleMatchFeedback,
  // Admin routes
  handleGetAllUsers,
  handleToggleSuperadmin,
  handleGetAllMatches,
  handleGetUserMatchingDetails,
} from './routes';

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  console.log('=== Lambda Function Start ===');
  console.log('Path:', event.path);
  console.log('Method:', event.httpMethod);
  console.log('Origin:', event.headers.origin || event.headers.Origin);
  
  // Get the request origin for CORS
  const requestOrigin = event.headers.origin || event.headers.Origin;
  
  // Handle CORS preflight requests
  if (event.httpMethod === 'OPTIONS') {
    return handleCorsPreflightRequest(requestOrigin);
  }
  
  try {
    // Route handling based on path
    let response: APIGatewayProxyResult;
    
    switch (event.path) {
      case '/profile':
        response = await handleProfile(event);
        break;
      case '/login':
        response = await handleLogin(event);
        break;
      case '/auth-validate':
        response = await handleAuthValidate(event);
        break;
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
      case '/delete-cove':
        return handleDeleteCove(event);
      case '/event':
        response = await handleGetEvent(event);
        break;
      case '/user-coves':
        return handleGetUserCoves(event);
      case '/update-event-rsvp':
        return handleUpdateEventRSVP(event);
      case '/remove-event-rsvp':
        return handleRemoveEventRSVP(event);
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
      // Post routes
      case '/create-post':
        return handleCreatePost(event);
      case '/cove-posts':
        return handleGetCovePosts(event);
      case '/post':
        return handleGetPost(event);
      case '/toggle-post-like':
        return handleTogglePostLike(event);
      // Feed routes
      case '/feed':
        return handleGetFeed(event);
      // Event member management routes  
      case '/event-members':
        return handleGetEventMembers(event);
      case '/pending-members':
        return handleGetPendingMembers(event);
      case '/approve-decline-rsvp':
        return handleApproveDeclineRSVP(event);
      case '/universities':
        return handleGetUniversities(event);
      case '/sms-webhook':
        return handleSMSWebhook(event);
      // Vendor routes
      case '/vendor/login':
        return handleVendorLogin(event);
      case '/vendor/validate-code':
        return handleValidateVendorCode(event);
      case '/vendor/create-organization':
        return handleCreateVendorOrganization(event);
      case '/vendor/onboard':
        return handleVendorOnboard(event);
      case '/vendor/join-organization':
        return handleJoinVendorOrganization(event);
      case '/vendor/profile':
        response = await handleGetVendorProfile(event);
        break;
      case '/vendor/rotate-code':
        return handleRotateVendorCode(event);
      case '/vendor/members':
        return handleGetVendorMembers(event);
      case '/vendor/create-event':
        return handleCreateVendorEvent(event);
      case '/vendor/events':
        return handleGetVendorEvents(event);
      case '/vendor/image':
        return handleVendorImageUpload(event);
      case '/vendor/image/update':
        return handleVendorImageUpdate(event);
      // AI Matching routes
      case '/survey/submit':
        return handleSurveySubmit(event);
      case '/survey':
        return handleGetSurvey(event);
      case '/intention':
        return handleCreateIntention(event);
      case '/intention/status':
        return handleGetIntentionStatus(event);
      case '/match/current':
        return handleGetCurrentMatch(event);
      // Admin routes (superadmin only)
      case '/admin/users':
        return handleGetAllUsers(event);
      case '/admin/toggle-superadmin':
        return handleToggleSuperadmin(event);
      case '/admin/matches':
        return handleGetAllMatches(event);
      case '/admin/user-details':
        return handleGetUserMatchingDetails(event);
      default:
        // Handle dynamic AI Matching routes with path parameters
        if (event.path.startsWith('/intention/') && event.httpMethod === 'DELETE') {
          const intentionId = event.path.split('/')[2];
          event.pathParameters = { id: intentionId };
          return handleDeleteIntention(event);
        }
        if (event.path.startsWith('/match/') && event.path.endsWith('/accept')) {
          const matchId = event.path.split('/')[2];
          event.pathParameters = { id: matchId };
          return handleAcceptMatch(event);
        }
        if (event.path.startsWith('/match/') && event.path.endsWith('/decline')) {
          const matchId = event.path.split('/')[2];
          event.pathParameters = { id: matchId };
          return handleDeclineMatch(event);
        }
        if (event.path.startsWith('/match/') && event.path.endsWith('/feedback')) {
          const matchId = event.path.split('/')[2];
          event.pathParameters = { id: matchId };
          return handleMatchFeedback(event);
        }
        
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
        
        response = {
          statusCode: 404,
          body: JSON.stringify({ 
            message: 'Not Found',
            path: event.path
          })
        };
        break;
    }
    
    // Add CORS headers to all responses
    return addCorsHeaders(response, requestOrigin);
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : 'Unknown error');
    console.error('Stack:', error instanceof Error ? error.stack : 'No stack trace');
    
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    
    return addCorsHeaders(errorResponse, requestOrigin);
  }
};

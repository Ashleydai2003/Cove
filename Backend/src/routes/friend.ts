import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';

/**
 * Handles sending friend requests
 * 
 * Request body:
 * - toUserId: ID of the user to send the request to
 * 
 * Returns:
 * - 200: Friend request sent successfully
 * - 400: Missing or invalid request body
 * - 401: Unauthorized
 * - 403: Cannot send request to yourself
 * - 404: Target user not found
 * - 409: Friend request already exists
 * - 500: Server error
 */
export const handleSendFriendRequest = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted.'
        })
      };
    }

    // Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Get the authenticated user's ID
    const fromUserId = authResult.user.uid;

    // Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { toUserId } = JSON.parse(event.body);
    if (!toUserId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'toUserId is required in request body'
        })
      };
    }

    // Prevent sending request to yourself
    if (fromUserId === toUserId) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Cannot send friend request to yourself'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Check if target user exists
    const targetUser = await prisma.user.findUnique({
      where: { id: toUserId }
    });

    if (!targetUser) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Target user not found'
        })
      };
    }

    // Check if a friend request already exists
    const existingRequest = await prisma.friendRequest.findUnique({
      where: {
        fromUserId_toUserId: {
          fromUserId,
          toUserId
        }
      }
    });

    if (existingRequest) {
      return {
        statusCode: 409,
        body: JSON.stringify({
          message: 'Friend request already exists'
        })
      };
    }

    // Check if they are already friends
    const existingFriendship = await prisma.friendship.findFirst({
      where: {
        OR: [
          { user1Id: fromUserId, user2Id: toUserId },
          { user1Id: toUserId, user2Id: fromUserId }
        ]
      }
    });

    if (existingFriendship) {
      return {
        statusCode: 409,
        body: JSON.stringify({
          message: 'Users are already friends'
        })
      };
    }

    // Create the friend request
    const friendRequest = await prisma.friendRequest.create({
      data: {
        fromUserId,
        toUserId
      }
    });

    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Friend request sent successfully',
        requestId: friendRequest.id
      })
    };
  } catch (error) {
    console.error('Send friend request error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing friend request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
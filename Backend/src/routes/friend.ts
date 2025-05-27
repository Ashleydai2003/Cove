import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';

/**
 * Handles sending friend requests
 * 
 * Request body:
 * - toUserIds: Array of user IDs to send requests to
 * 
 * Returns:
 * - 200: Friend requests sent successfully
 * - 400: Missing or invalid request body
 * - 401: Unauthorized
 * - 403: Cannot send request to yourself
 * - 404: One or more target users not found
 * - 409: One or more friend requests already exist
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

    const { toUserIds } = JSON.parse(event.body);
    if (!Array.isArray(toUserIds) || toUserIds.length === 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'toUserIds is required in request body'
        })
      };
    }

    // Prevent sending request to yourself
    if (toUserIds.includes(fromUserId)) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Cannot send friend request to yourself'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Check if all target users exist
    const targetUsers = await prisma.user.findMany({
      where: { id: { in: toUserIds } }
    });

    if (targetUsers.length !== toUserIds.length) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'One or more target users not found'
        })
      };
    }

    // Check for existing friend requests and friendships
    const existingRequests = await prisma.friendRequest.findMany({
      where: {
        fromUserId,
        toUserId: { in: toUserIds }
      }
    });

    const existingFriendships = await prisma.friendship.findMany({
      where: {
        OR: [
          { user1Id: fromUserId, user2Id: { in: toUserIds } },
          { user1Id: { in: toUserIds }, user2Id: fromUserId }
        ]
      }
    });

    if (existingRequests.length > 0 || existingFriendships.length > 0) {
      return {
        statusCode: 409,
        body: JSON.stringify({
          message: 'One or more friend requests already exist or users are already friends'
        })
      };
    }

    // Create all friend requests
    const friendRequests = await Promise.all(
      toUserIds.map(toUserId =>
        prisma.friendRequest.create({
          data: {
            fromUserId,
            toUserId
          }
        })
      )
    );

    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Friend requests sent successfully',
        requestIds: friendRequests.map(req => req.id)
      })
    };
  } catch (error) {
    console.error('Send friend request error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing friend requests',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Handles resolving friend requests (accept/reject)
 * 
 * Request body:
 * - requestId: ID of the friend request to resolve
 * - accept: boolean - true to accept, false to reject
 * 
 * Returns:
 * - 200: Friend request resolved successfully
 * - 400: Missing or invalid request body
 * - 401: Unauthorized
 * - 403: Not authorized to resolve this request
 * - 404: Friend request not found
 * - 500: Server error
 */
export const handleResolveFriendRequest = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
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
    const userId = authResult.user.uid;

    // Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { requestId, accept } = JSON.parse(event.body);
    if (!requestId || typeof accept !== 'boolean') {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'requestId and accept (boolean) are required in request body'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Find the friend request
    const friendRequest = await prisma.friendRequest.findUnique({
      where: { id: requestId }
    });

    if (!friendRequest) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Friend request not found'
        })
      };
    }

    // Verify the user is the recipient of the request
    if (friendRequest.toUserId !== userId) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Not authorized to resolve this friend request'
        })
      };
    }

    if (accept) {
      // Create friendship
      await prisma.friendship.create({
        data: {
          user1Id: friendRequest.fromUserId,
          user2Id: friendRequest.toUserId
        }
      });
    }

    // Delete the friend request (whether accepted or rejected)
    await prisma.friendRequest.delete({
      where: { id: requestId }
    });

    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: `Friend request ${accept ? 'accepted' : 'rejected'} successfully`
      })
    };
  } catch (error) {
    console.error('Resolve friend request error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing friend request resolution',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
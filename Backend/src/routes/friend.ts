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

/**
 * Handles getting all friends for a user with pagination
 * 
 * Query Parameters:
 * - cursor: ID of the last friendship from previous request (optional)
 * - limit: number of friends to return (optional, defaults to 10, max 50)
 * 
 * Returns:
 * - 200: Friends retrieved successfully
 * - 401: Unauthorized
 * - 500: Server error
 * 
 * Response Format:
 * {
 *   friends: [
 *     {
 *       id: string,          // Friend's user ID
 *       name: string,        // Friend's name
 *       profilePhotoUrl: string | null,  // URL of friend's profile photo
 *       friendshipId: string,  // ID of the friendship record
 *       createdAt: Date      // When the friendship was created
 *     }
 *   ],
 *   pagination: {
 *     hasMore: boolean,      // Whether there are more friends to load
 *     nextCursor: string | null  // ID to use for next page of results
 *   }
 * }
 */
export const handleGetFriends = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted.'
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

    // Get pagination parameters
    // cursor: ID of the last friendship from previous request (for pagination)
    // limit: number of friends to return (defaults to 10, max 50)
    const cursor = event.queryStringParameters?.cursor;
    const requestedLimit = parseInt(event.queryStringParameters?.limit || '10');
    const limit = Math.min(requestedLimit, 50); // Enforce maximum limit of 50

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Get friendships where the user is either user1 or user2
    // We fetch limit + 1 items to determine if there are more results
    const friendships = await prisma.friendship.findMany({
      where: {
        OR: [
          { user1Id: userId },
          { user2Id: userId }
        ]
      },
      include: {
        // Include user1's details (id, name, and profile photo)
        user1: {
          select: {
            id: true,
            name: true,
            profilePhoto: {
              select: {
                id: true
              }
            }
          }
        },
        // Include user2's details (id, name, and profile photo)
        user2: {
          select: {
            id: true,
            name: true,
            profilePhoto: {
              select: {
                id: true
              }
            }
          }
        }
      },
      // Order by most recent friendships first
      orderBy: {
        createdAt: 'desc'
      },
      // Take one extra item to determine if there are more results
      take: limit + 1,
      // If cursor exists, skip the cursor item and start after it
      ...(cursor ? {
        cursor: {
          id: cursor
        },
        skip: 1
      } : {})
    });

    // Check if there are more results by comparing actual length with requested limit
    const hasMore = friendships.length > limit;
    // Remove the extra item we fetched if there are more results
    const friendshipsToReturn = hasMore ? friendships.slice(0, -1) : friendships;

    // Return success response with friends and pagination info
    return {
      statusCode: 200,
      body: JSON.stringify({
        friends: friendshipsToReturn.map(friendship => {
          // Determine which user is the friend (not the current user)
          // If current user is user1, friend is user2, and vice versa
          const friend = friendship.user1Id === userId ? friendship.user2 : friendship.user1;
          
          // Get the friend's profile photo URL
          const profilePhotoUrl = friend.profilePhoto ? 
            `${process.env.USER_IMAGE_BUCKET_URL}/${friend.id}/${friend.profilePhoto.id}.jpg` : 
            null;
          
          return {
            id: friend.id,
            name: friend.name,
            profilePhotoUrl,
            friendshipId: friendship.id,
            createdAt: friendship.createdAt
          };
        }),
        pagination: {
          hasMore,
          // If there are more results, use the last item's ID as the next cursor
          nextCursor: hasMore ? friendships[friendships.length - 2].id : null
        }
      })
    };
  } catch (error) {
    console.error('Get friends error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error retrieving friends',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Handles getting all pending friend requests for a user with pagination
 * 
 * Query Parameters:
 * - cursor: ID of the last request from previous request (optional)
 * - limit: number of requests to return (optional, defaults to 10, max 50)
 * 
 * Returns:
 * - 200: Friend requests retrieved successfully
 * - 401: Unauthorized
 * - 500: Server error
 * 
 * Response Format:
 * {
 *   requests: [
 *     {
 *       id: string,          // Friend request ID
 *       sender: {
 *         id: string,        // Sender's user ID
 *         name: string,      // Sender's name
 *         profilePhotoUrl: string | null  // URL of sender's profile photo
 *       },
 *       createdAt: Date      // When the request was sent
 *     }
 *   ],
 *   pagination: {
 *     hasMore: boolean,      // Whether there are more requests to load
 *     nextCursor: string | null  // ID to use for next page of results
 *   }
 * }
 */
export const handleGetFriendRequests = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted.'
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

    // Get pagination parameters
    // cursor: ID of the last request from previous request (for pagination)
    // limit: number of requests to return (defaults to 10, max 50)
    const cursor = event.queryStringParameters?.cursor;
    const requestedLimit = parseInt(event.queryStringParameters?.limit || '10');
    const limit = Math.min(requestedLimit, 50); // Enforce maximum limit of 50

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Get friend requests where the user is the recipient
    // We fetch limit + 1 items to determine if there are more results
    const requests = await prisma.friendRequest.findMany({
      where: {
        toUserId: userId
      },
      include: {
        // Include sender's details (id, name, and profile photo)
        fromUser: {
          select: {
            id: true,
            name: true,
            profilePhoto: {
              select: {
                id: true
              }
            }
          }
        }
      },
      // Order by most recent requests first
      orderBy: {
        createdAt: 'desc'
      },
      // Take one extra item to determine if there are more results
      take: limit + 1,
      // If cursor exists, skip the cursor item and start after it
      ...(cursor ? {
        cursor: {
          id: cursor
        },
        skip: 1
      } : {})
    });

    // Check if there are more results by comparing actual length with requested limit
    const hasMore = requests.length > limit;
    // Remove the extra item we fetched if there are more results
    const requestsToReturn = hasMore ? requests.slice(0, -1) : requests;

    // Return success response with requests and pagination info
    return {
      statusCode: 200,
      body: JSON.stringify({
        requests: requestsToReturn.map(request => {
          // Get the sender's profile photo URL
          const profilePhotoUrl = request.fromUser.profilePhoto ? 
            `${process.env.USER_IMAGE_BUCKET_URL}/${request.fromUser.id}/${request.fromUser.profilePhoto.id}.jpg` : 
            null;
          
          return {
            id: request.id,
            sender: {
              id: request.fromUser.id,
              name: request.fromUser.name,
              profilePhotoUrl
            },
            createdAt: request.createdAt
          };
        }),
        pagination: {
          hasMore,
          // If there are more results, use the last item's ID as the next cursor
          nextCursor: hasMore ? requests[requests.length - 2].id : null
        }
      })
    };
  } catch (error) {
    console.error('Get friend requests error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error retrieving friend requests',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
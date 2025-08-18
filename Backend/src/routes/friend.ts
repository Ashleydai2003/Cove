import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { s3Client } from '../config/s3';
import * as admin from 'firebase-admin';

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

    // Send push notifications to recipients who have FCM tokens
    try {
      const [sender, recipients] = await Promise.all([
        prisma.user.findUnique({ where: { id: fromUserId }, select: { name: true } }),
        prisma.user.findMany({ where: { id: { in: toUserIds } }, select: { id: true, fcmToken: true } })
      ]);
      const senderName = sender?.name || 'Someone';
      for (const r of recipients) {
        if (r.fcmToken) {
          try {
            await admin.messaging().send({
              token: r.fcmToken,
              notification: {
                title: '💌 New friend request',
                body: `${senderName} wants to connect on Cove`
              },
              data: {
                type: 'friend_request',
                senderId: fromUserId
              }
            });
          } catch (err) {
            console.error('Error sending friend request notification:', err);
          }
        }
      }
    } catch (notifyErr) {
      console.error('Friend request notify error:', notifyErr);
    }

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
 * - action: string - "ACCEPT" to accept, "REJECT" to reject
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

    const { requestId, action } = JSON.parse(event.body);
    if (!requestId || !action || !['ACCEPT', 'REJECT'].includes(action)) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'requestId and action ("ACCEPT" or "REJECT") are required in request body'
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

    if (action === 'ACCEPT') {
      // Create friendship
      await prisma.friendship.create({
        data: {
          user1Id: friendRequest.fromUserId,
          user2Id: friendRequest.toUserId
        }
      });

      // Notify original sender that their request was accepted
      try {
        const [sender, recipient, senderToken] = await Promise.all([
          prisma.user.findUnique({ where: { id: friendRequest.fromUserId }, select: { id: true } }),
          prisma.user.findUnique({ where: { id: friendRequest.toUserId }, select: { name: true } }),
          prisma.user.findUnique({ where: { id: friendRequest.fromUserId }, select: { fcmToken: true } })
        ]);
        const recipientName = recipient?.name || 'Someone';
        if (sender && senderToken?.fcmToken) {
          await admin.messaging().send({
            token: senderToken.fcmToken,
            notification: {
              title: '💫 It\'s mutual',
              body: `${recipientName} accepted your friend request`
            },
            data: {
              type: 'friend_request_accepted',
              userId: friendRequest.toUserId
            }
          });
        }
      } catch (notifyErr) {
        console.error('Friend accept notify error:', notifyErr);
      }
    }

    // Delete the friend request (whether accepted or rejected)
    await prisma.friendRequest.delete({
      where: { id: requestId }
    });

    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: `Friend request ${action.toLowerCase()}ed successfully`
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
        friends: await Promise.all(friendshipsToReturn.map(async friendship => {
          // Determine which user is the friend (not the current user)
          const friend = friendship.user1Id === userId ? friendship.user2 : friendship.user1;
          
          // Generate profile photo URL if it exists
          const profilePhotoUrl = friend.profilePhoto ? 
            await getSignedUrl(s3Client, new GetObjectCommand({
              Bucket: process.env.USER_IMAGE_BUCKET_NAME,
              Key: `${friend.id}/${friend.profilePhoto.id}.jpg`
            }), { expiresIn: 3600 }) : 
            null;
          
          return {
            id: friend.id,
            name: friend.name,
            profilePhotoUrl,
            friendshipId: friendship.id,
            createdAt: friendship.createdAt
          };
        })),
        pagination: {
          hasMore,
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
    console.log('🔍 Getting friend requests for userId:', userId);

    // Get pagination parameters
    // cursor: ID of the last request from previous request (for pagination)
    // limit: number of requests to return (defaults to 10, max 50)
    const cursor = event.queryStringParameters?.cursor;
    const requestedLimit = parseInt(event.queryStringParameters?.limit || '10');
    const limit = Math.min(requestedLimit, 50); // Enforce maximum limit of 50
    console.log('📄 Pagination - cursor:', cursor, 'limit:', limit);

    // Initialize database connection
    const prisma = await initializeDatabase();

    // First, let's check if there are ANY friend requests for this user at all
    const allRequestsCount = await prisma.friendRequest.count({
      where: {
        toUserId: userId
      }
    });
    console.log('📊 Total friend requests for user:', allRequestsCount);

    // Also check all friend requests in the database 
    const totalFriendRequests = await prisma.friendRequest.count();
    console.log('📊 Total friend requests in database:', totalFriendRequests);

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

    console.log('🔍 Query results - found', requests.length, 'friend requests');
    console.log('📝 Friend request details:', requests.map(r => ({ 
      id: r.id, 
      fromUserId: r.fromUserId, 
      toUserId: r.toUserId, 
      fromUserName: r.fromUser?.name 
    })));

    // Check if there are more results by comparing actual length with requested limit
    const hasMore = requests.length > limit;
    // Remove the extra item we fetched if there are more results
    const requestsToReturn = hasMore ? requests.slice(0, -1) : requests;
    
    console.log('✅ Final results - returning', requestsToReturn.length, 'requests, hasMore:', hasMore);

    // Return success response with requests and pagination info
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        requests: await Promise.all(requestsToReturn.map(async request => {
          // Generate profile photo URL if it exists
          const profilePhotoUrl = request.fromUser.profilePhoto ? 
            await getSignedUrl(s3Client, new GetObjectCommand({
              Bucket: process.env.USER_IMAGE_BUCKET_NAME,
              Key: `${request.fromUser.id}/${request.fromUser.profilePhoto.id}.jpg`
            }), { expiresIn: 3600 }) : 
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
        })),
        pagination: {
          hasMore,
          nextCursor: hasMore ? requests[requests.length - 2].id : null
        }
      })
    };
    
    console.log('📤 Response:', JSON.stringify(response, null, 2));
    return response;
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


// TODO: there's a lot of database queries here, we should try to optimize this 
/**
 * Get recommended friends
 * 
 * This endpoint handles retrieving users who are in at least one cove with the current user.
 * 
 * The endpoint returns:
 * - Paginated list of users with basic information (id, name, profile photo)
 * - Number of coves they share with the current user
 * - When they joined their most recent shared cove
 * 
 * Error cases:
 * - 405: Invalid HTTP method
 * - 500: Server error
 */
export const handleGetRecommendedFriends = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving recommended friends.'
        })
      };
    }

    // Authenticate the request using Firebase
    const authResult = await authMiddleware(event);
    
    // If auth failed, return the error response
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Get the authenticated user's info from Firebase
    const user = authResult.user;
    console.log('Authenticated user:', user.uid);

    // Get pagination parameters
    // cursor: ID of the last user from previous request (for pagination)
    // limit: number of users to return (defaults to 10, max 50)
    const cursor = event.queryStringParameters?.cursor;
    const requestedLimit = parseInt(event.queryStringParameters?.limit || '10');
    const limit = Math.min(requestedLimit, 50); // Enforce maximum limit of 50
    console.log('🔍 Pagination params - cursor:', cursor, 'limit:', limit);

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Get all coves where the current user is a member
    const userCoveIds = await prisma.coveMember.findMany({
      where: { userId: user.uid },
      select: { coveId: true }
    });
    console.log('🏘️ User is member of', userCoveIds.length, 'coves:', userCoveIds.map(c => c.coveId));

    if (userCoveIds.length === 0) {
      // User is not in any coves, return empty result
      console.log('❌ User not in any coves, returning empty result');
      return {
        statusCode: 200,
        body: JSON.stringify({
          users: [],
          pagination: {
            hasMore: false,
            nextCursor: null
          }
        })
      };
    }

    const userCoveIdList = userCoveIds.map(member => member.coveId);

    // Get all cove members from the user's coves, excluding the user themselves
    const allCoveMembers = await prisma.coveMember.findMany({
      where: {
        coveId: { in: userCoveIdList },
        userId: { not: user.uid }
      },
      include: {
        user: {
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
      orderBy: {
        joinedAt: 'desc'
      }
    });
    console.log('👥 Found', allCoveMembers.length, 'cove members (excluding current user)');

    // Get users to exclude (friends, sent requests, received requests)
    const [existingFriendships, sentRequests, receivedRequests] = await Promise.all([
      // Get existing friendships
      prisma.friendship.findMany({
        where: {
          OR: [
            { user1Id: user.uid },
            { user2Id: user.uid }
          ]
        },
        select: {
          user1Id: true,
          user2Id: true
        }
      }),
      // Get sent friend requests
      prisma.friendRequest.findMany({
        where: { fromUserId: user.uid },
        select: { toUserId: true }
      }),
      // Get received friend requests
      prisma.friendRequest.findMany({
        where: { toUserId: user.uid },
        select: { fromUserId: true }
      })
    ]);
    console.log('🚫 Exclusions - Friends:', existingFriendships.length, 'Sent requests:', sentRequests.length, 'Received requests:', receivedRequests.length);

    // Create a set of user IDs to exclude
    const excludedUserIds = new Set<string>();
    
    // Add friends
    existingFriendships.forEach(friendship => {
      if (friendship.user1Id === user.uid) {
        excludedUserIds.add(friendship.user2Id);
      } else {
        excludedUserIds.add(friendship.user1Id);
      }
    });
    
    // Add users we've sent requests to
    sentRequests.forEach(request => {
      excludedUserIds.add(request.toUserId);
    });
    
    // Add users who have sent us requests
    receivedRequests.forEach(request => {
      excludedUserIds.add(request.fromUserId);
    });

    // Group by user and count shared coves, excluding the filtered users
    const userCoveCounts = new Map<string, {
      user: any;
      sharedCoveCount: number;
    }>();

    for (const member of allCoveMembers) {
      const userId = member.user.id;
      
      // Skip if user is in the excluded list
      if (excludedUserIds.has(userId)) {
        continue;
      }
      
      const existing = userCoveCounts.get(userId);
      
      if (existing) {
        existing.sharedCoveCount++;
      } else {
        userCoveCounts.set(userId, {
          user: member.user,
          sharedCoveCount: 1
        });
      }
    }

    // Convert to array and sort by shared cove count (descending)
    const sortedUsers = Array.from(userCoveCounts.values())
      .sort((a, b) => b.sharedCoveCount - a.sharedCoveCount);
    console.log('✅ After filtering and sorting, found', sortedUsers.length, 'potential recommended friends');
    console.log('🎯 Top 3 candidates:', sortedUsers.slice(0, 3).map(u => ({ id: u.user.id, name: u.user.name, sharedCoves: u.sharedCoveCount })));

    // Apply pagination
    let startIndex = 0;
    if (cursor) {
      const cursorIndex = sortedUsers.findIndex(u => u.user.id === cursor);
      if (cursorIndex !== -1) {
        startIndex = cursorIndex + 1;
      }
      console.log('📄 Cursor pagination - cursor:', cursor, 'startIndex:', startIndex);
    }

    const endIndex = startIndex + limit;
    const hasMore = endIndex < sortedUsers.length;
    const usersToReturn = sortedUsers.slice(startIndex, endIndex);
    console.log('📊 Final result - returning', usersToReturn.length, 'users, hasMore:', hasMore);

    // Return success response with users and pagination info
    return {
      statusCode: 200,
      body: JSON.stringify({
        users: await Promise.all(usersToReturn.map(async userData => {
          // Generate profile photo URL if it exists
          const profilePhotoUrl = userData.user.profilePhoto ? 
            await getSignedUrl(s3Client, new GetObjectCommand({
              Bucket: process.env.USER_IMAGE_BUCKET_NAME,
              Key: `${userData.user.id}/${userData.user.profilePhoto.id}.jpg`
            }), { expiresIn: 3600 }) : 
            null;

          return {
            id: userData.user.id,
            name: userData.user.name,
            profilePhotoUrl,
            sharedCoveCount: userData.sharedCoveCount
          };
        })),
        pagination: {
          hasMore,
          nextCursor: hasMore ? usersToReturn[usersToReturn.length - 1].user.id : null
        }
      })
    };
  } catch (error) {
    console.error('Get recommended friends route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get recommended friends request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};
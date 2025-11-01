// Admin routes - require superadmin access

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';

/**
 * Verify superadmin access - reusable helper
 */
async function verifySuperadmin(userId: string): Promise<boolean> {
  const prisma = await initializeDatabase();
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { superadmin: true }
  });
  return user?.superadmin || false;
}

/**
 * Get all users - SUPERADMIN ONLY
 * Returns a list of all users with basic info
 */
export const handleGetAllUsers = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is GET
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    
    // Step 2: Check if auth failed
    if ('statusCode' in authResult) {
      return authResult;
    }

    const userId = authResult.user.uid;

    // Step 3: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 4: STRICT CHECK - Verify user is superadmin
    const isSuperadmin = await verifySuperadmin(userId);
    if (!isSuperadmin) {
      console.log(`[Admin] Unauthorized access attempt by user ${userId}`);
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Forbidden. Superadmin access required.'
        })
      };
    }

    console.log(`[Admin] Superadmin ${userId} accessing user list`);

    // Step 5: Fetch all users with relevant info
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        phone: true,
        onboarding: true,
        verified: true,
        superadmin: true,
        createdAt: true,
        profile: {
          select: {
            age: true,
            city: true,
            almaMater: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    // Step 6: Format the response
    const formattedUsers = users.map(user => ({
      id: user.id,
      name: user.name || 'N/A',
      phone: user.phone,
      onboarding: user.onboarding,
      verified: user.verified,
      superadmin: user.superadmin,
      createdAt: user.createdAt.toISOString(),
      age: user.profile?.age || null,
      city: user.profile?.city || null,
      almaMater: user.profile?.almaMater || null
    }));

    return {
      statusCode: 200,
      body: JSON.stringify({
        users: formattedUsers,
        count: formattedUsers.length
      })
    };
  } catch (error) {
    console.error('Admin get users error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error fetching users',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Toggle user superadmin status - SUPERADMIN ONLY
 * Allows a superadmin to grant/revoke superadmin access to other users
 */
export const handleToggleSuperadmin = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    
    if ('statusCode' in authResult) {
      return authResult;
    }

    const userId = authResult.user.uid;

    // Step 2: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 3: STRICT CHECK - Verify user is superadmin
    const isSuperadmin = await verifySuperadmin(userId);
    if (!isSuperadmin) {
      console.log(`[Admin] Unauthorized superadmin toggle attempt by user ${userId}`);
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Forbidden. Superadmin access required.'
        })
      };
    }

    // Step 4: Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { targetUserId, superadmin } = JSON.parse(event.body);

    if (!targetUserId || typeof superadmin !== 'boolean') {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Invalid request: targetUserId and superadmin (boolean) are required'
        })
      };
    }

    // Step 5: Update target user's superadmin status
    await prisma.user.update({
      where: { id: targetUserId },
      data: { superadmin }
    });

    console.log(`[Admin] User ${userId} set superadmin=${superadmin} for user ${targetUserId}`);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Superadmin status updated successfully',
        targetUserId,
        superadmin
      })
    };
  } catch (error) {
    console.error('Admin toggle superadmin error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error updating superadmin status',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Get all matches - SUPERADMIN ONLY
 * Returns all matches with member details
 */
export const handleGetAllMatches = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is GET
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    
    if ('statusCode' in authResult) {
      return authResult;
    }

    const userId = authResult.user.uid;

    // Step 2: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 3: STRICT CHECK - Verify user is superadmin
    const isSuperadmin = await verifySuperadmin(userId);
    if (!isSuperadmin) {
      console.log(`[Admin] Unauthorized match access attempt by user ${userId}`);
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Forbidden. Superadmin access required.'
        })
      };
    }

    console.log(`[Admin] Superadmin ${userId} accessing matches list`);

    // Step 4: Fetch all matches with members
    const matches = await prisma.match.findMany({
      include: {
        members: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                phone: true,
                profile: {
                  select: {
                    age: true,
                    city: true,
                    almaMater: true
                  }
                }
              }
            }
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    // Step 5: Format the response
    const formattedMatches = matches.map(match => ({
      id: match.id,
      groupSize: match.groupSize,
      status: match.status,
      score: match.score,
      tierUsed: match.tierUsed,
      createdAt: match.createdAt.toISOString(),
      members: match.members.map(member => ({
        userId: member.userId,
        name: member.user.name || 'N/A',
        phone: member.user.phone,
        age: member.user.profile?.age || null,
        city: member.user.profile?.city || null,
        almaMater: member.user.profile?.almaMater || null
      }))
    }));

    return {
      statusCode: 200,
      body: JSON.stringify({
        matches: formattedMatches,
        count: formattedMatches.length
      })
    };
  } catch (error) {
    console.error('Admin get matches error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error fetching matches',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Get user matching details - SUPERADMIN ONLY
 * Returns survey responses, active intention, and past intentions for a user
 */
export const handleGetUserMatchingDetails = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is GET
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    
    if ('statusCode' in authResult) {
      return authResult;
    }

    const requestingUserId = authResult.user.uid;

    // Step 2: Get target user ID from query params
    const targetUserId = event.queryStringParameters?.userId;
    if (!targetUserId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Missing userId query parameter'
        })
      };
    }

    // Step 3: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 4: STRICT CHECK - Verify requesting user is superadmin
    const isSuperadmin = await verifySuperadmin(requestingUserId);
    if (!isSuperadmin) {
      console.log(`[Admin] Unauthorized user details access attempt by user ${requestingUserId}`);
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Forbidden. Superadmin access required.'
        })
      };
    }

    console.log(`[Admin] Superadmin ${requestingUserId} accessing details for user ${targetUserId}`);

    // Step 5: Fetch user details
    const user = await prisma.user.findUnique({
      where: { id: targetUserId },
      select: {
        id: true,
        name: true,
        phone: true,
        profile: {
          select: {
            age: true,
            city: true,
            almaMater: true
          }
        }
      }
    });

    if (!user) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'User not found'
        })
      };
    }

    // Step 6: Fetch survey responses
    const surveyResponses = await prisma.surveyResponse.findMany({
      where: { userId: targetUserId },
      select: {
        questionId: true,
        value: true,
        createdAt: true
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    // Step 7: Fetch active intention with pool entry
    const activeIntention = await prisma.intention.findFirst({
      where: {
        userId: targetUserId,
        status: 'active'
      },
      include: {
        poolEntry: true
      }
    });

    // Step 8: Fetch past intentions
    const pastIntentions = await prisma.intention.findMany({
      where: {
        userId: targetUserId,
        status: { in: ['expired', 'matched'] }
      },
      orderBy: {
        createdAt: 'desc'
      },
      take: 10
    });

    // Step 9: Format the response
    console.log('📤 [AdminUserDetails] Active intention parsedJson type:', typeof activeIntention?.parsedJson);
    console.log('📤 [AdminUserDetails] Active intention parsedJson value:', JSON.stringify(activeIntention?.parsedJson));

    const response = {
      user: {
        id: user.id,
        name: user.name || 'N/A',
        phone: user.phone,
        age: user.profile?.age || null,
        city: user.profile?.city || null,
        almaMater: user.profile?.almaMater || null
      },
      survey: surveyResponses.map(r => ({
        questionId: r.questionId,
        value: r.value,
        answeredAt: r.createdAt.toISOString()
      })),
      activeIntention: activeIntention ? {
        id: activeIntention.id,
        text: activeIntention.text,
        parsedJson: activeIntention.parsedJson, // Already a JS object from Prisma
        status: activeIntention.status,
        createdAt: activeIntention.createdAt.toISOString(),
        validUntil: activeIntention.validUntil.toISOString(),
        poolEntry: activeIntention.poolEntry ? {
          tier: activeIntention.poolEntry.tier,
          joinedAt: activeIntention.poolEntry.joinedAt.toISOString()
        } : null
      } : null,
      pastIntentions: pastIntentions.map(i => ({
        id: i.id,
        text: i.text,
        parsedJson: i.parsedJson, // Already a JS object from Prisma
        status: i.status,
        createdAt: i.createdAt.toISOString(),
        validUntil: i.validUntil.toISOString()
      }))
    };

    return {
      statusCode: 200,
      body: JSON.stringify(response)
    };
  } catch (error) {
    console.error('Admin get user details error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error fetching user matching details',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};


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

    // Step 5: Get pagination parameters
    const page = parseInt(event.queryStringParameters?.page || '0');
    const limit = parseInt(event.queryStringParameters?.limit || '20');
    const skip = page * limit;

    console.log(`[Admin] Fetching users - page: ${page}, limit: ${limit}, skip: ${skip}`);

    // Step 6: Fetch users with pagination
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
      },
      skip,
      take: limit
    });

    // Step 7: Format the response
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

    // Step 4: Get pagination parameters
    const page = parseInt(event.queryStringParameters?.page || '0');
    const limit = parseInt(event.queryStringParameters?.limit || '20');
    const skip = page * limit;

    console.log(`[Admin] Fetching matches - page: ${page}, limit: ${limit}, skip: ${skip}`);

    // Step 5: Fetch matches with pagination
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
      },
      skip,
      take: limit
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
        parsedJson: activeIntention.parsedJson,
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
        parsedJson: i.parsedJson,
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

/**
 * GET /admin/unmatched-users
 * Fetch users with active intentions but no matches (paginated)
 */
export const handleGetUnmatchedUsers = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
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

    const userId = authResult.user.uid;

    // Initialize database connection
    const prisma = await initializeDatabase();

    // STRICT CHECK - Verify user is superadmin
    const isSuperadmin = await verifySuperadmin(userId);
    if (!isSuperadmin) {
      console.log(`[Admin] Unauthorized unmatched users access attempt by user ${userId}`);
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Forbidden. Superadmin access required.'
        })
      };
    }

    console.log(`[Admin] Superadmin ${userId} accessing unmatched users`);

    // Get pagination parameters
    const page = parseInt(event.queryStringParameters?.page || '0');
    const limit = parseInt(event.queryStringParameters?.limit || '20');
    const skip = page * limit;

    console.log(`[Admin] Fetching unmatched users - page: ${page}, limit: ${limit}, skip: ${skip}`);
    
    // Fetch pool entries with pagination - having a pool entry means they're unmatched
    const poolEntries = await prisma.poolEntry.findMany({
      select: {
        intentionId: true,
        tier: true,
        joinedAt: true,
        intention: {
          select: {
            id: true,
            userId: true,
            text: true,
            parsedJson: true,
            status: true,
            createdAt: true,
            validUntil: true,
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
      where: {
        intention: {
          status: 'active'
        }
      },
      orderBy: {
        tier: 'desc'
      },
      skip,
      take: limit
    });
    
    // Format the response
    const formattedUsers = poolEntries.map(entry => ({
      user: {
        id: entry.intention.user.id,
        name: entry.intention.user.name || 'N/A',
        phone: entry.intention.user.phone,
        age: entry.intention.user.profile?.age || null,
        city: entry.intention.user.profile?.city || null,
        almaMater: entry.intention.user.profile?.almaMater || null
      },
      activeIntention: {
        id: entry.intention.id,
        text: entry.intention.text,
        parsedJson: entry.intention.parsedJson,
        status: entry.intention.status,
        createdAt: entry.intention.createdAt.toISOString(),
        validUntil: entry.intention.validUntil.toISOString(),
        poolEntry: {
          tier: entry.tier,
          joinedAt: entry.joinedAt.toISOString()
        }
      }
    }));

    return {
      statusCode: 200,
      body: JSON.stringify({
        users: formattedUsers,
        count: formattedUsers.length
      })
    };
  } catch (error) {
    console.error('Admin get unmatched users error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error fetching unmatched users',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * POST /admin/matches/create
 * Manually create a match with specified users - SUPERADMIN ONLY
 * Body: {
 *   userIds: string[],
 *   tierUsed?: number,
 *   score?: number
 * }
 */
export const handleCreateManualMatch = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
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

    const userId = authResult.user.uid;

    // Initialize database connection
    const prisma = await initializeDatabase();

    // STRICT CHECK - Verify user is superadmin
    const isSuperadmin = await verifySuperadmin(userId);
    if (!isSuperadmin) {
      console.log(`[Admin] Unauthorized manual match creation attempt by user ${userId}`);
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Forbidden. Superadmin access required.'
        })
      };
    }

    // Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { userIds, tierUsed, score } = JSON.parse(event.body);

    if (!userIds || !Array.isArray(userIds) || userIds.length < 2) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Invalid request: at least 2 userIds required'
        })
      };
    }

    // Verify all users exist and have active intentions
    const users = await prisma.user.findMany({
      where: {
        id: { in: userIds }
      },
      include: {
        intentions: {
          where: {
            status: 'active'
          }
        }
      }
    });

    if (users.length !== userIds.length) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'One or more users not found'
        })
      };
    }

    // Check all users have active intentions
    const usersWithoutIntentions = users.filter(u => u.intentions.length === 0);
    if (usersWithoutIntentions.length > 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: `Users without active intentions: ${usersWithoutIntentions.map(u => u.name).join(', ')}`
        })
      };
    }

    // Create match with 7-day expiration
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    const match = await prisma.match.create({
      data: {
        groupSize: userIds.length,
        score: score ?? 0.8,
        tierUsed: tierUsed ?? 0,
        expiresAt,
        status: 'active',
        members: {
          create: users.map(user => ({
            userId: user.id,
            intentionId: user.intentions[0].id
          }))
        }
      },
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
      }
    });

    // Remove users from pool (they've been matched)
    await prisma.poolEntry.deleteMany({
      where: {
        intentionId: {
          in: users.map(u => u.intentions[0].id)
        }
      }
    });

    console.log(`[Admin] Superadmin ${userId} created manual match ${match.id} with ${userIds.length} users`);

    return {
      statusCode: 201,
      body: JSON.stringify({
        message: 'Match created successfully',
        match: {
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
        }
      })
    };
  } catch (error) {
    console.error('Admin create manual match error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error creating manual match',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * POST /admin/matches/:matchId/add-member
 * Add a user to an existing match - SUPERADMIN ONLY
 * Body: {
 *   userId: string
 * }
 */
export const handleAddMatchMember = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
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

    const requestingUserId = authResult.user.uid;

    // Initialize database connection
    const prisma = await initializeDatabase();

    // STRICT CHECK - Verify user is superadmin
    const isSuperadmin = await verifySuperadmin(requestingUserId);
    if (!isSuperadmin) {
      console.log(`[Admin] Unauthorized add member attempt by user ${requestingUserId}`);
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Forbidden. Superadmin access required.'
        })
      };
    }

    const matchId = event.pathParameters?.matchId;
    if (!matchId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Match ID required'
        })
      };
    }

    // Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { userId } = JSON.parse(event.body);

    if (!userId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'userId required in request body'
        })
      };
    }

    // Verify match exists
    const match = await prisma.match.findUnique({
      where: { id: matchId },
      include: {
        members: true
      }
    });

    if (!match) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Match not found'
        })
      };
    }

    // Check if user is already in this match
    if (match.members.some(m => m.userId === userId)) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'User is already a member of this match'
        })
      };
    }

    // Verify user exists and has an active intention
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        intentions: {
          where: {
            status: 'active'
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

    if (user.intentions.length === 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'User does not have an active intention'
        })
      };
    }

    // Add user to match
    await prisma.$transaction([
      prisma.matchMember.create({
        data: {
          matchId,
          userId,
          intentionId: user.intentions[0].id
        }
      }),
      prisma.match.update({
        where: { id: matchId },
        data: {
          groupSize: match.groupSize + 1
        }
      }),
      // Remove from pool if they were there
      prisma.poolEntry.deleteMany({
        where: {
          intentionId: user.intentions[0].id
        }
      })
    ]);

    console.log(`[Admin] Superadmin ${requestingUserId} added user ${userId} to match ${matchId}`);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'User added to match successfully'
      })
    };
  } catch (error) {
    console.error('Admin add match member error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error adding user to match',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * POST /admin/matches/:matchId/remove-member
 * Remove a user from a match - SUPERADMIN ONLY
 * Body: {
 *   userId: string,
 *   returnToPool?: boolean
 * }
 */
export const handleRemoveMatchMember = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
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

    const requestingUserId = authResult.user.uid;

    // Initialize database connection
    const prisma = await initializeDatabase();

    // STRICT CHECK - Verify user is superadmin
    const isSuperadmin = await verifySuperadmin(requestingUserId);
    if (!isSuperadmin) {
      console.log(`[Admin] Unauthorized remove member attempt by user ${requestingUserId}`);
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Forbidden. Superadmin access required.'
        })
      };
    }

    const matchId = event.pathParameters?.matchId;
    if (!matchId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Match ID required'
        })
      };
    }

    // Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { userId, returnToPool } = JSON.parse(event.body);

    if (!userId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'userId required in request body'
        })
      };
    }

    // Verify match exists
    const match = await prisma.match.findUnique({
      where: { id: matchId },
      include: {
        members: true
      }
    });

    if (!match) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Match not found'
        })
      };
    }

    // Check if user is in this match
    const member = match.members.find(m => m.userId === userId);
    if (!member) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'User is not a member of this match'
        })
      };
    }

    // Special case: if removing from a 2-person match, delete the match and return both to pool
    if (match.groupSize === 2) {
      const operations: any[] = [];
      
      // Get all intention IDs from this match
      const intentionIds = match.members.map(m => m.intentionId);
      
      // Find active intentions
      const activeIntentions = await prisma.intention.findMany({
        where: {
          id: { in: intentionIds },
          status: 'active'
        }
      });

      // Delete the match (members cascade delete)
      operations.push(
        prisma.match.delete({
          where: { id: matchId }
        })
      );

      // Return all members with active intentions to pool
      for (const intention of activeIntentions) {
        operations.push(
          prisma.poolEntry.create({
            data: {
              intentionId: intention.id,
              tier: 0
            }
          })
        );
      }

      await prisma.$transaction(operations);

      console.log(`[Admin] Superadmin ${requestingUserId} removed user ${userId} from 2-person match ${matchId}, deleted match and returned remaining user to pool`);

      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'User removed from match. Match deleted and remaining user returned to pool.'
        })
      };
    }

    // For matches with 3+ people, just remove the user
    const operations: any[] = [
      prisma.matchMember.delete({
        where: {
          id: member.id
        }
      }),
      prisma.match.update({
        where: { id: matchId },
        data: {
          groupSize: match.groupSize - 1
        }
      })
    ];

    // Optionally return removed user to pool
    if (returnToPool) {
      // Check if intention is still active
      const intention = await prisma.intention.findUnique({
        where: { id: member.intentionId }
      });

      if (intention && intention.status === 'active') {
        operations.push(
          prisma.poolEntry.create({
            data: {
              intentionId: member.intentionId,
              tier: 0
            }
          })
        );
      }
    }

    await prisma.$transaction(operations);

    console.log(`[Admin] Superadmin ${requestingUserId} removed user ${userId} from match ${matchId}`);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: returnToPool 
          ? 'User removed from match and returned to pool'
          : 'User removed from match successfully'
      })
    };
  } catch (error) {
    console.error('Admin remove match member error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error removing user from match',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * POST /admin/matches/:fromMatchId/move-member
 * Move a user from one match to another - SUPERADMIN ONLY
 * Body: {
 *   userId: string,
 *   toMatchId: string
 * }
 */
export const handleMoveMatchMember = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
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

    const requestingUserId = authResult.user.uid;

    // Initialize database connection
    const prisma = await initializeDatabase();

    // STRICT CHECK - Verify user is superadmin
    const isSuperadmin = await verifySuperadmin(requestingUserId);
    if (!isSuperadmin) {
      console.log(`[Admin] Unauthorized move member attempt by user ${requestingUserId}`);
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Forbidden. Superadmin access required.'
        })
      };
    }

    const fromMatchId = event.pathParameters?.fromMatchId;
    if (!fromMatchId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Match ID required'
        })
      };
    }

    // Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { userId, toMatchId } = JSON.parse(event.body);

    if (!userId || !toMatchId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'userId and toMatchId required in request body'
        })
      };
    }

    // Verify both matches exist
    const [fromMatch, toMatch] = await Promise.all([
      prisma.match.findUnique({
        where: { id: fromMatchId },
        include: { members: true }
      }),
      prisma.match.findUnique({
        where: { id: toMatchId },
        include: { members: true }
      })
    ]);

    if (!fromMatch) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Source match not found'
        })
      };
    }

    if (!toMatch) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Destination match not found'
        })
      };
    }

    // Check if user is in source match
    const member = fromMatch.members.find(m => m.userId === userId);
    if (!member) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'User is not a member of the source match'
        })
      };
    }

    // Check if user is already in destination match
    if (toMatch.members.some(m => m.userId === userId)) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'User is already a member of the destination match'
        })
      };
    }

    // Special case: if moving from a 2-person match, delete source match and return other user to pool
    if (fromMatch.groupSize === 2) {
      const operations: any[] = [];
      
      // Find the other user in the source match
      const otherMember = fromMatch.members.find(m => m.userId !== userId);
      
      if (otherMember) {
        // Check if other user's intention is still active
        const otherIntention = await prisma.intention.findUnique({
          where: { id: otherMember.intentionId }
        });

        // Delete the source match
        operations.push(
          prisma.match.delete({
            where: { id: fromMatchId }
          })
        );

        // Return other user to pool if their intention is active
        if (otherIntention && otherIntention.status === 'active') {
          operations.push(
            prisma.poolEntry.create({
              data: {
                intentionId: otherIntention.id,
                tier: 0
              }
            })
          );
        }
      }

      // Add moved user to destination match
      operations.push(
        prisma.matchMember.create({
          data: {
            matchId: toMatchId,
            userId,
            intentionId: member.intentionId
          }
        }),
        prisma.match.update({
          where: { id: toMatchId },
          data: { groupSize: toMatch.groupSize + 1 }
        })
      );

      await prisma.$transaction(operations);

      console.log(`[Admin] Superadmin ${requestingUserId} moved user ${userId} from 2-person match ${fromMatchId} to ${toMatchId}, deleted source match and returned other user to pool`);

      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'User moved successfully. Source match deleted and remaining user returned to pool.'
        })
      };
    }

    // For matches with 3+ people, just move the user normally
    await prisma.$transaction([
      // Remove from source match
      prisma.matchMember.delete({
        where: { id: member.id }
      }),
      prisma.match.update({
        where: { id: fromMatchId },
        data: { groupSize: fromMatch.groupSize - 1 }
      }),
      // Add to destination match
      prisma.matchMember.create({
        data: {
          matchId: toMatchId,
          userId,
          intentionId: member.intentionId
        }
      }),
      prisma.match.update({
        where: { id: toMatchId },
        data: { groupSize: toMatch.groupSize + 1 }
      })
    ]);

    console.log(`[Admin] Superadmin ${requestingUserId} moved user ${userId} from match ${fromMatchId} to ${toMatchId}`);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'User moved between matches successfully'
      })
    };
  } catch (error) {
    console.error('Admin move match member error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error moving user between matches',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * DELETE /admin/matches/:matchId
 * Delete a match - SUPERADMIN ONLY
 * Query params:
 *   returnToPool=true/false (optional, default: false)
 */
export const handleDeleteMatch = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'DELETE') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only DELETE requests are accepted.'
        })
      };
    }

    // Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    const requestingUserId = authResult.user.uid;

    // Initialize database connection
    const prisma = await initializeDatabase();

    // STRICT CHECK - Verify user is superadmin
    const isSuperadmin = await verifySuperadmin(requestingUserId);
    if (!isSuperadmin) {
      console.log(`[Admin] Unauthorized delete match attempt by user ${requestingUserId}`);
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Forbidden. Superadmin access required.'
        })
      };
    }

    const matchId = event.pathParameters?.matchId;
    if (!matchId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Match ID required'
        })
      };
    }

    const returnToPool = event.queryStringParameters?.returnToPool === 'true';

    // Verify match exists
    const match = await prisma.match.findUnique({
      where: { id: matchId },
      include: {
        members: true
      }
    });

    if (!match) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Match not found'
        })
      };
    }

    // If returning to pool, create pool entries for all members with active intentions
    if (returnToPool) {
      const intentionIds = match.members.map(m => m.intentionId);
      const activeIntentions = await prisma.intention.findMany({
        where: {
          id: { in: intentionIds },
          status: 'active'
        }
      });

      const poolEntryPromises = activeIntentions.map(intention =>
        prisma.poolEntry.create({
          data: {
            intentionId: intention.id,
            tier: 0
          }
        })
      );

      await Promise.all(poolEntryPromises);
    }

    // Delete match (members will cascade delete)
    await prisma.match.delete({
      where: { id: matchId }
    });

    console.log(`[Admin] Superadmin ${requestingUserId} deleted match ${matchId}`);

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: returnToPool 
          ? 'Match deleted and members returned to pool'
          : 'Match deleted successfully'
      })
    };
  } catch (error) {
    console.error('Admin delete match error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error deleting match',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};


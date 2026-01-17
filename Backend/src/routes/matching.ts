// /Backend/src/routes/matching.ts

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';

// MARK: - Survey Endpoints

/**
 * POST /survey/submit
 * Saves or updates user's survey responses
 * 
 * Body: {
 *   responses: [
 *     { questionId: "alumni_network", value: "Stanford", isMustHave: true },
 *     { questionId: "age_band", value: "21-24", isMustHave: false },
 *     { questionId: "city", value: "Palo Alto", isMustHave: true },
 *     { questionId: "availability", value: JSON.stringify(["Sat evening", "Sun daytime"]), isMustHave: true },
 *     { questionId: "activities", value: JSON.stringify(["Live music", "Art walk"]), isMustHave: false },
 *     { questionId: "vibe", value: JSON.stringify(["Outgoing"]), isMustHave: false },
 *     { questionId: "dealbreakers", value: JSON.stringify(["Under 21"]), isMustHave: false }
 *   ]
 * }
 */
export async function handleSurveySubmit(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    console.log('🔍 [DEBUG] Survey submit request received');
    console.log('🔍 [DEBUG] Headers:', JSON.stringify(event.headers, null, 2));
    console.log('🔍 [DEBUG] Body:', event.body);
    
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      console.log('❌ [DEBUG] Auth failed:', JSON.stringify(authResult, null, 2));
      return authResult;
    }
    const userId = authResult.user.uid;
    
    const prisma = await initializeDatabase();
    console.log('✅ [DEBUG] User authenticated:', userId);

    const body = JSON.parse(event.body || '{}');
    const { responses } = body;
    console.log('🔍 [DEBUG] Parsed responses:', JSON.stringify(responses, null, 2));

    if (!responses || !Array.isArray(responses)) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Invalid request: responses array required' })
      };
    }

    // Validate each response
    for (const response of responses) {
      if (!response.questionId || !response.value) {
        return {
          statusCode: 400,
          body: JSON.stringify({ message: 'Invalid response: questionId and value required' })
        };
      }
    }

    // Use transaction to update all responses
    console.log('🔍 [DEBUG] Starting database transaction for', responses.length, 'responses');
    await prisma.$transaction(
      responses.map((response: any) => {
        console.log('🔍 [DEBUG] Processing response:', response.questionId, '=', response.value);
        return prisma.surveyResponse.upsert({
          where: {
            userId_questionId: {
              userId,
              questionId: response.questionId
            }
          },
          create: {
            userId,
            questionId: response.questionId,
            value: response.value,
            isMustHave: response.isMustHave ?? false
          },
          update: {
            value: response.value,
            isMustHave: response.isMustHave ?? false,
            updatedAt: new Date()
          }
        });
      })
    );
    console.log('✅ [DEBUG] Database transaction completed successfully');

    // Note: City and alma mater should come from user's existing profile, not survey

    return {
      statusCode: 200,
      body: JSON.stringify({
        responses: responses.map((response: any) => ({
          questionId: response.questionId,
          value: response.value,
          isMustHave: response.isMustHave ?? false
        }))
      })
    };
  } catch (error) {
    console.error('Error saving survey:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error saving survey responses',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}

/**
 * GET /survey
 * Retrieves user's survey responses
 */
export async function handleGetSurvey(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }
    const userId = authResult.user.uid;
    
    const prisma = await initializeDatabase();

    const responses = await prisma.surveyResponse.findMany({
      where: { userId },
      orderBy: { questionId: 'asc' }
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        responses: responses.map(r => ({
          questionId: r.questionId,
          value: r.value,
          isMustHave: r.isMustHave,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt
        }))
      })
    };
  } catch (error) {
    console.error('Error retrieving survey:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error retrieving survey responses',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}

// MARK: - Intention Endpoints

/**
 * POST /intention
 * Creates a new intention and enters user into the matching pool
 * 
 * Body: {
 *   text: "Looking for a Stanford alum to hit the Palo Alto art walk this weekend",
 *   chips: {
 *     who: { network: "Stanford", ageBand: "21-24", genderPref: "any" },
 *     what: { activities: ["Art walk"], notes: "" },
 *     when: ["Sat evening"],
 *     where: "Palo Alto",
 *     vibe: ["Outgoing"],
 *     mustHaves: ["network", "when", "where"],
 *     dealbreakers: ["Under 21"]
 *   }
 * }
 */
export async function handleCreateIntention(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }
    const userId = authResult.user.uid;
    
    const prisma = await initializeDatabase();

    const body = JSON.parse(event.body || '{}');
    const { chips } = body;

    if (!chips) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Invalid request: chips required' })
      };
    }

    // Validate current structure: { who: {}, what: { intention, activities }, when: [], where: "", mustHaves: [] }
    // LEGACY SUPPORT: Also support old structures for backward compatibility
    let intention: string;
    let activities: string[];
    let availability: string[];
    let location: string;

    if (chips.what && chips.what.intention) {
      // Current format
      intention = chips.what.intention;
      activities = chips.what.activities || [];
      availability = chips.when || [];
      location = chips.where || '';
    } else if (chips.what && chips.what.notes) {
      // LEGACY SUPPORT: Old format with what.notes
      // Try to extract intention from notes
      const notes = chips.what.notes.toLowerCase();
      intention = notes.includes('dating') || notes.includes('romantic') ? 'romantic' : 'friends';
      activities = chips.what.activities || [];
      availability = chips.when || [];
      location = chips.location || '';
    } else {
      return {
        statusCode: 400,
        body: JSON.stringify({ 
          message: 'Invalid request: chips must include what.intention, what.activities, when, and where' 
        })
      };
    }

    // Validate intention type
    if (!['friends', 'romantic'].includes(intention)) {
      return {
        statusCode: 400,
        body: JSON.stringify({ 
          message: 'Invalid intention: must be "friends" or "romantic"' 
        })
      };
    }

    // Validate arrays
    if (!Array.isArray(activities) || !Array.isArray(availability)) {
      return {
        statusCode: 400,
        body: JSON.stringify({ 
          message: 'Invalid request: activities and availability must be arrays' 
        })
      };
    }

    // Validate required fields
    if (activities.length === 0 || availability.length === 0 || !location) {
      return {
        statusCode: 400,
        body: JSON.stringify({ 
          message: 'Invalid request: activities, availability, and location are required' 
        })
      };
    }

    // Check if user already has an active intention
    // Note: The partial unique index enforces only one active intention per user
    const existingActiveIntention = await prisma.intention.findFirst({
      where: {
        userId,
        status: 'active'
      }
    });

    if (existingActiveIntention) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'User already has an active intention. Please delete or update it first.',
          existingIntentionId: existingActiveIntention.id
        })
      };
    }

    // Calculate valid until (3 days from now)
    const validUntil = new Date();
    validUntil.setHours(validUntil.getHours() + 72);

    // Create intention and pool entry in a transaction
    const result = await prisma.$transaction(async (tx) => {
      const intention = await tx.intention.create({
        data: {
          userId,
          text: '', // Deprecated - using parsedJson only
          parsedJson: chips,
          validUntil,
          status: 'active'
        }
      });

      const poolEntry = await tx.poolEntry.create({
        data: {
          intentionId: intention.id,
          tier: 0
        }
      });

      return { intention, poolEntry };
    });

    // Calculate next batch ETA (next 3-hour interval)
    const now = new Date();
    const currentHour = now.getUTCHours();
    const nextBatchHour = Math.ceil((currentHour + 1) / 3) * 3;
    const nextBatchEta = new Date(now);
    nextBatchEta.setUTCHours(nextBatchHour, 0, 0, 0);
    if (nextBatchEta <= now) {
      nextBatchEta.setUTCHours(nextBatchEta.getUTCHours() + 3);
    }

    return {
      statusCode: 201,
      body: JSON.stringify({
        message: 'Intention created successfully',
        intention: {
          id: result.intention.id,
          text: result.intention.text,
          parsedJson: result.intention.parsedJson,
          validUntil: result.intention.validUntil.toISOString(),
          status: result.intention.status
        },
        poolEntry: {
          tier: result.poolEntry.tier,
          nextBatchEta: nextBatchEta.toISOString()
        }
      })
    };
  } catch (error) {
    console.error('Error creating intention:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error creating intention',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}

/**
 * GET /intention/status
 * Retrieves current intention and pool status
 */
export async function handleGetIntentionStatus(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }
    const userId = authResult.user.uid;
    
    const prisma = await initializeDatabase();

    const intention = await prisma.intention.findFirst({
      where: {
        userId,
        status: 'active'
      },
      include: {
        poolEntry: true,
        user: {
          include: {
            profile: true
          }
        }
      }
    });

    if (!intention) {
      return {
        statusCode: 200,
        body: JSON.stringify({
          hasIntention: false,
          intention: null,
          poolEntry: null
        })
      };
    }

    // Calculate next batch ETA
    const now = new Date();
    const currentHour = now.getUTCHours();
    const nextBatchHour = Math.ceil((currentHour + 1) / 3) * 3;
    const nextBatchEta = new Date(now);
    nextBatchEta.setUTCHours(nextBatchHour, 0, 0, 0);
    if (nextBatchEta <= now) {
      nextBatchEta.setUTCHours(nextBatchEta.getUTCHours() + 3);
    }

    // Check if user has a match
    const match = await prisma.match.findFirst({
      where: {
        members: {
          some: {
            userId: userId
          }
        },
        status: 'active'
      }
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        hasIntention: true,
        userName: intention.user.name || 'there',
        intention: {
          id: intention.id,
          text: intention.text,
          parsedJson: intention.parsedJson,
          validUntil: intention.validUntil.toISOString(),
          status: intention.status
        },
        poolEntry: intention.poolEntry ? {
          tier: intention.poolEntry.tier,
          joinedAt: intention.poolEntry.joinedAt?.toISOString() || null,
          nextBatchEta: nextBatchEta.toISOString()
        } : null,
        hasMatch: !!match
      })
    };
  } catch (error) {
    console.error('Error retrieving intention status:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error retrieving intention status',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}

/**
 * DELETE /intention/:id
 * Deletes an intention and removes user from pool
 */
export async function handleDeleteIntention(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }
    const userId = authResult.user.uid;
    
    const prisma = await initializeDatabase();

    const intentionId = event.pathParameters?.id;
    
    if (!intentionId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Intention ID required' })
      };
    }

    // Verify intention belongs to user
    const intention = await prisma.intention.findUnique({
      where: { id: intentionId }
    });

    if (!intention) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Intention not found' })
      };
    }

    if (intention.userId !== userId) {
      return {
        statusCode: 403,
        body: JSON.stringify({ message: 'Not authorized to delete this intention' })
      };
    }

    // Delete intention (pool entry will cascade delete)
    await prisma.intention.delete({
      where: { id: intentionId }
    });

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Intention deleted successfully' })
    };
  } catch (error) {
    console.error('Error deleting intention:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error deleting intention',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}

// MARK: - Match Endpoints

/**
 * GET /match/current
 * Retrieves user's current active match
 */
export async function handleGetCurrentMatch(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }
    const userId = authResult.user.uid;
    
    const prisma = await initializeDatabase();

    // Find active match
    const match = await prisma.match.findFirst({
      where: {
        members: {
          some: {
            userId: userId
          }
        },
        status: 'active'
      },
      include: {
        members: {
          include: {
            user: {
              include: {
                profile: true,
                profilePhoto: true
              }
            },
            intention: true
          }
        }
      }
    });

    if (!match) {
      return {
        statusCode: 200,
        body: JSON.stringify({
          hasMatch: false,
          match: null
        })
      };
    }

    // Find the matched user (not the current user)
    const currentUserMember = match.members.find(member => member.userId === userId);
    const matchedUserMember = match.members.find(member => member.userId !== userId);
    
    if (!matchedUserMember) {
      return {
        statusCode: 500,
        body: JSON.stringify({ message: 'Match data corrupted' })
      };
    }
    
    const matchedUser = matchedUserMember.user;
    const matchedIntention = matchedUserMember.intention;
    const currentIntention = currentUserMember?.intention;

    // Get profile photo URL
    let profilePhotoUrl = null;
    if (matchedUser.profilePhoto) {
      // Assuming you have a getPresignedUrl function
      // profilePhotoUrl = await getPresignedUrl(matchedUser.profilePhoto.id);
      profilePhotoUrl = `https://your-s3-bucket.com/${matchedUser.profilePhoto.id}`; // Placeholder
    }

    // Build "matched on" array
    const matchedOn: string[] = [];
    const currentChips = currentIntention?.parsedJson as any;
    const matchedChips = matchedIntention.parsedJson as any;

    // Compare activities
    if (currentChips.what?.activities && matchedChips.what?.activities) {
      const commonActivities = currentChips.what.activities.filter((a: string) =>
        matchedChips.what.activities.includes(a)
      );
      if (commonActivities.length > 0) {
        matchedOn.push(`Activity: ${commonActivities.join(', ')}`);
      }
    }

    // Compare time windows
    if (currentChips.when && matchedChips.when) {
      const commonTimes = currentChips.when.filter((t: string) =>
        matchedChips.when.includes(t)
      );
      if (commonTimes.length > 0) {
        matchedOn.push(`Time: ${commonTimes.join(', ')}`);
      }
    }

    // Compare location
    if (currentChips.where === matchedChips.where) {
      matchedOn.push(`Location: ${currentChips.where}`);
    }

    // Compare alumni network
    if (matchedUser.profile?.almaMater) {
      matchedOn.push(`Alumni network: ${matchedUser.profile.almaMater}`);
    }

    // Build "relaxed constraints" array based on tier
    const relaxedConstraints: string[] = [];
    if (match.tierUsed === 1) {
      relaxedConstraints.push('Expanded search radius to adjacent areas');
    } else if (match.tierUsed === 2) {
      relaxedConstraints.push('Expanded search radius to region');
      relaxedConstraints.push('Adjacent time windows included');
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        hasMatch: true,
        match: {
          id: match.id,
          matchedUserId: matchedUser.id,
          score: match.score,
          tierUsed: match.tierUsed,
          matchedOn,
          relaxedConstraints,
          createdAt: match.createdAt.toISOString(),
          expiresAt: match.expiresAt.toISOString(),
          groupSize: match.groupSize,
          user: {
            name: matchedUser.name,
            age: matchedUser.profile?.age,
            almaMater: matchedUser.profile?.almaMater,
            bio: matchedUser.profile?.bio,
            gender: matchedUser.profile?.gender,
            profilePhotoUrl
          }
        }
      })
    };
  } catch (error) {
    console.error('Error retrieving current match:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error retrieving current match',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}

/**
 * POST /match/:id/accept
 * Accepts a match and creates a messaging thread
 */
export async function handleAcceptMatch(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }
    const userId = authResult.user.uid;
    
    const prisma = await initializeDatabase();

    const matchId = event.pathParameters?.id;
    
    if (!matchId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Match ID required' })
      };
    }

    // Verify match exists and user is part of it
    const match = await prisma.match.findUnique({
      where: { id: matchId },
      include: {
        members: true
      }
    });

    if (!match) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Match not found' })
      };
    }

    const userMember = match.members.find(member => member.userId === userId);
    if (!userMember) {
      return {
        statusCode: 403,
        body: JSON.stringify({ message: 'Not authorized to accept this match' })
      };
    }

    // For now, only support 1-on-1 matches (groupSize = 2)
    if (match.groupSize !== 2) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Group matches not yet supported for acceptance' })
      };
    }

    // Determine the other user
    const otherUserMember = match.members.find(member => member.userId !== userId);
    if (!otherUserMember) {
      return {
        statusCode: 500,
        body: JSON.stringify({ message: 'Match data corrupted' })
      };
    }
    const otherUserId = otherUserMember.userId;

    // Create or get existing thread
    let thread = await prisma.thread.findFirst({
      where: {
        AND: [
          { members: { some: { userId } } },
          { members: { some: { userId: otherUserId } } }
        ]
      }
    });

    if (!thread) {
      // Create new thread with both users
      thread = await prisma.thread.create({
        data: {
          members: {
            create: [
              { userId },
              { userId: otherUserId }
            ]
          }
        }
      });
    }

    // Update match status
    await prisma.match.update({
      where: { id: matchId },
      data: {
        status: 'accepted',
        threadId: thread.id
      }
    });

    // Update all intentions to matched status
    const intentionIds = match.members.map(member => member.intentionId);
    await prisma.intention.updateMany({
      where: {
        id: {
          in: intentionIds
        }
      },
      data: {
        status: 'matched'
      }
    });

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Match accepted successfully',
        threadId: thread.id
      })
    };
  } catch (error) {
    console.error('Error accepting match:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error accepting match',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}

/**
 * POST /match/:id/decline
 * Declines a match and re-enters user into pool
 */
export async function handleDeclineMatch(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }
    const userId = authResult.user.uid;
    
    const prisma = await initializeDatabase();

    const matchId = event.pathParameters?.id;
    
    if (!matchId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Match ID required' })
      };
    }

    // Verify match exists and user is part of it
    const match = await prisma.match.findUnique({
      where: { id: matchId },
      include: {
        members: true
      }
    });

    if (!match) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Match not found' })
      };
    }

    const userMember = match.members.find(member => member.userId === userId);
    if (!userMember) {
      return {
        statusCode: 403,
        body: JSON.stringify({ message: 'Not authorized to decline this match' })
      };
    }

    // Update match status
    await prisma.match.update({
      where: { id: matchId },
      data: { status: 'declined' }
    });

    // User's intention remains active, so they'll be back in the pool for next batch

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Match declined. You will be included in the next matching batch.'
      })
    };
  } catch (error) {
    console.error('Error declining match:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error declining match',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}

/**
 * POST /match/:id/feedback
 * Submits feedback for a match
 */
export async function handleMatchFeedback(
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> {
  try {
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }
    const userId = authResult.user.uid;
    
    const prisma = await initializeDatabase();

    const matchId = event.pathParameters?.id;
    
    if (!matchId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Match ID required' })
      };
    }

    const body = JSON.parse(event.body || '{}');
    const { matchedOn, wasAccurate } = body;

    if (!matchedOn || !Array.isArray(matchedOn)) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Invalid request: matchedOn array required' })
      };
    }

    // Verify match exists and user is part of it
    const match = await prisma.match.findUnique({
      where: { id: matchId },
      include: {
        members: true
      }
    });

    if (!match) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Match not found' })
      };
    }

    const userMember = match.members.find(member => member.userId === userId);
    if (!userMember) {
      return {
        statusCode: 403,
        body: JSON.stringify({ message: 'Not authorized to provide feedback for this match' })
      };
    }

    // Create feedback
    await prisma.matchFeedback.create({
      data: {
        matchId,
        userId,
        matchedOn,
        wasAccurate: wasAccurate ?? null
      }
    });

    return {
      statusCode: 201,
      body: JSON.stringify({ message: 'Feedback submitted successfully' })
    };
  } catch (error) {
    console.error('Error submitting match feedback:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error submitting match feedback',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}


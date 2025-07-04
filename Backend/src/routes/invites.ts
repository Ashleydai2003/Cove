import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';

/**
 * Handles GET requests to retrieve invites for the authenticated user
 * Returns all invites sent to the user's phone number
 * 
 * Returns:
 * - 200: List of invites with cove and sender info
 * - 401: Unauthorized
 * - 404: User not found
 * - 405: Method not allowed
 * - 500: Server error
 */
export const handleGetInvites = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving invites.'
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

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Get the user's phone number to find invites
    const userData = await prisma.user.findUnique({
      where: { id: user.uid },
      select: { phone: true }
    });

    if (!userData) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'User not found'
        })
      };
    }

    // Get all invites for the user's phone number
    const invites = await prisma.invite.findMany({
      where: {
        phoneNumber: userData.phone
      },
      include: {
        cove: {
          select: {
            id: true,
            name: true,
            description: true,
            location: true,
            coverPhotoID: true
          }
        },
        sentBy: {
          select: {
            id: true,
            name: true,
            profilePhotoID: true
          }
        }
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    // Mark invites as opened when retrieved
    if (invites.length > 0) {
      await prisma.invite.updateMany({
        where: {
          id: {
            in: invites.map(invite => invite.id)
          },
          isOpened: false
        },
        data: {
          isOpened: true
        }
      });
    }

    // Return success response with invites
    return {
      statusCode: 200,
      body: JSON.stringify({
        invites: invites.map(invite => ({
          id: invite.id,
          message: invite.message,
          createdAt: invite.createdAt,
          isOpened: invite.isOpened,
          cove: {
            id: invite.cove.id,
            name: invite.cove.name,
            description: invite.cove.description,
            location: invite.cove.location,
            coverPhotoId: invite.cove.coverPhotoID
          },
          sentBy: {
            id: invite.sentBy.id,
            name: invite.sentBy.name,
            profilePhotoId: invite.sentBy.profilePhotoID
          }
        }))
      })
    };
  } catch (error) {
    console.error('Get invites route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get invites request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Handles POST requests to send cove invites to phone numbers
 * Allows cove admins to invite others to join their cove
 * 
 * Request body:
 * - coveId: ID of the cove to invite to (required)
 * - phoneNumbers: Array of phone numbers to invite (required)
 * - message: Optional invitation message
 * 
 * Returns:
 * - 200: Successfully sent invites
 * - 400: Invalid request body or missing fields
 * - 401: Unauthorized
 * - 403: Not an admin of the cove
 * - 404: Cove not found
 * - 405: Method not allowed
 * - 500: Server error
 */
export const handleSendInvite = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only POST is allowed
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for sending invites.'
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

    // Parse and validate request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { coveId, phoneNumbers, message } = JSON.parse(event.body);

    // Validate required fields
    if (!coveId || !phoneNumbers || !Array.isArray(phoneNumbers) || phoneNumbers.length === 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Cove ID and phone numbers array are required'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Check if user is an admin of the cove
    const cove = await prisma.cove.findUnique({
      where: { id: coveId },
      include: {
        members: {
          where: { 
            userId: user.uid,
            role: 'ADMIN'
          }
        }
      }
    });

    // Check if the cove exists
    if (!cove) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Cove not found'
        })
      };
    }

    // Check if user is an admin of the cove
    if (cove.members.length === 0) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'You must be an admin of this cove to send invites'
        })
      };
    }

    // Create invites for each phone number
    const inviteResults = [];
    const errors = [];

    for (const phoneNumber of phoneNumbers) {
      try {
        // Check if invite already exists for this phone number and cove
        const existingInvite = await prisma.invite.findUnique({
          where: {
            phoneNumber_coveId: {
              phoneNumber: phoneNumber,
              coveId: coveId
            }
          }
        });

        if (existingInvite) {
          errors.push({
            phoneNumber,
            error: 'Invite already exists for this phone number'
          });
          continue;
        }

        // Check if user is already a member of the cove
        const existingMember = await prisma.user.findFirst({
          where: {
            phone: phoneNumber,
            coveMemberships: {
              some: {
                coveId: coveId
              }
            }
          }
        });

        if (existingMember) {
          errors.push({
            phoneNumber,
            error: 'User is already a member of this cove'
          });
          continue;
        }

        // Create the invite
        const invite = await prisma.invite.create({
          data: {
            phoneNumber: phoneNumber,
            coveId: coveId,
            sentByUserId: user.uid,
            message: message || null
          }
        });

        inviteResults.push({
          id: invite.id,
          phoneNumber: invite.phoneNumber,
          createdAt: invite.createdAt
        });
      } catch (error) {
        errors.push({
          phoneNumber,
          error: error instanceof Error ? error.message : 'Unknown error'
        });
      }
    }

    // Return success response with results and any errors
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: `Successfully sent ${inviteResults.length} invites`,
        invites: inviteResults,
        errors: errors.length > 0 ? errors : undefined
      })
    };
  } catch (error) {
    console.error('Send invite route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing send invite request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
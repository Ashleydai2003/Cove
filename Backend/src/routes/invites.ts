import AWS from 'aws-sdk';
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import * as admin from 'firebase-admin';

// Initialize S3 client for generating presigned URLs
const s3Client = new S3Client({ region: process.env.AWS_REGION || 'us-east-1' });

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

    // Return success response with invites
    return {
      statusCode: 200,
      body: JSON.stringify({
        invites: await Promise.all(invites.map(async invite => {
          // Generate cove cover photo URL if it exists
          let coverPhotoUrl = null;
          if (invite.cove.coverPhotoID) {
            try {
              const command = new GetObjectCommand({
                Bucket: process.env.COVE_IMAGE_BUCKET_NAME,
                Key: `${invite.cove.id}/${invite.cove.coverPhotoID}.jpg`
              });
              coverPhotoUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 });
            } catch (error) {
              console.error('Error generating cove cover photo URL:', error);
            }
          }

          return {
            id: invite.id,
            message: invite.message,
            createdAt: invite.createdAt,
            isOpened: invite.isOpened,
            cove: {
              id: invite.cove.id,
              name: invite.cove.name,
              description: invite.cove.description,
              location: invite.cove.location,
              coverPhotoId: invite.cove.coverPhotoID,
              coverPhotoUrl: coverPhotoUrl
            },
            sentBy: {
              id: invite.sentBy.id,
              name: invite.sentBy.name,
              profilePhotoId: invite.sentBy.profilePhotoID
            }
          };
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

        // If this phone number belongs to an existing user, notify them
        try {
          const [recipient, senderUser, coveInfo] = await Promise.all([
            prisma.user.findUnique({ where: { phone: phoneNumber }, select: { id: true, fcmToken: true } }),
            prisma.user.findUnique({ where: { id: user.uid }, select: { name: true } }),
            prisma.cove.findUnique({ where: { id: coveId }, select: { name: true } })
          ]);
                      if (recipient?.fcmToken) {
              if (process.env.NODE_ENV === 'production') {
                await admin.messaging().send({
                  token: recipient.fcmToken,
                  notification: {
                    title: '🔓 New cove unlocked',
                    body: `${senderUser?.name || 'Someone'} invited you to join ${coveInfo?.name || 'a cove'}`
                  },
                  data: {
                    type: 'cove_invite',
                    coveId,
                    inviteId: invite.id
                  }
                });
              } else {
                console.log('Skipping push notification in non-production (cove invite)');
              }
            }
        } catch (notifyErr) {
          console.error('Invite notify error:', notifyErr);
        }
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

/**
 * Handles PUT requests to mark an invite as opened
 * Updates the isOpened status of a specific invite
 * 
 * Request body:
 * - inviteId: ID of the invite to mark as opened (required)
 * 
 * Returns:
 * - 200: Successfully marked invite as opened
 * - 400: Invalid request body or missing fields
 * - 401: Unauthorized
 * - 404: Invite not found or not for this user
 * - 405: Method not allowed
 * - 500: Server error
 */
export const handleOpenInvite = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only PUT is allowed
    if (event.httpMethod !== 'PUT') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only PUT requests are accepted for opening invites.'
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

    const { inviteId } = JSON.parse(event.body);

    // Validate required fields
    if (!inviteId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Invite ID is required'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Get the user's phone number to verify invite ownership
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

    // Find and update the invite
    const invite = await prisma.invite.findFirst({
      where: {
        id: inviteId,
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
      }
    });

    if (!invite) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Invite not found or not for this user'
        })
      };
    }

    // Update the invite to mark as opened
    const updatedInvite = await prisma.invite.update({
      where: { id: inviteId },
      data: { isOpened: true }
    });

    // Generate cove cover photo URL if it exists
    let coverPhotoUrl = null;
    if (invite.cove.coverPhotoID) {
      try {
        const command = new GetObjectCommand({
          Bucket: process.env.COVE_IMAGE_BUCKET_NAME,
          Key: `${invite.cove.id}/${invite.cove.coverPhotoID}.jpg`
        });
        coverPhotoUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 });
      } catch (error) {
        console.error('Error generating cove cover photo URL for opened invite:', error);
      }
    }

    // Return success response with updated invite
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Invite marked as opened',
        invite: {
          id: updatedInvite.id,
          message: updatedInvite.message,
          createdAt: updatedInvite.createdAt,
          isOpened: updatedInvite.isOpened,
          cove: {
            id: invite.cove.id,
            name: invite.cove.name,
            description: invite.cove.description,
            location: invite.cove.location,
            coverPhotoId: invite.cove.coverPhotoID,
            coverPhotoUrl: coverPhotoUrl
          },
          sentBy: {
            id: invite.sentBy.id,
            name: invite.sentBy.name,
            profilePhotoId: invite.sentBy.profilePhotoID
          }
        }
      })
    };
  } catch (error) {
    console.error('Open invite route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing open invite request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Handles DELETE requests to reject/delete an invite
 * Removes the invite from the database after verifying ownership
 * 
 * Request body:
 * - inviteId: ID of the invite to reject/delete (required)
 * 
 * Returns:
 * - 200: Successfully rejected invite
 * - 400: Invalid request body or missing fields
 * - 401: Unauthorized
 * - 404: Invite not found or not for this user
 * - 405: Method not allowed
 * - 500: Server error
 */
export const handleRejectInvite = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only DELETE is allowed
    if (event.httpMethod !== 'DELETE') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only DELETE requests are accepted for rejecting invites.'
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

    const { inviteId } = JSON.parse(event.body);

    // Validate required fields
    if (!inviteId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Invite ID is required'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Get the user's phone number to verify invite ownership
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

    // Find the invite to verify it belongs to this user
    const invite = await prisma.invite.findFirst({
      where: {
        id: inviteId,
        phoneNumber: userData.phone
      }
    });

    if (!invite) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Invite not found or not for this user'
        })
      };
    }

    // Delete the invite
    await prisma.invite.delete({
      where: { id: inviteId }
    });

    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Invite rejected successfully'
      })
    };
  } catch (error) {
    console.error('Reject invite route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing reject invite request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

// Initialize S3 client for image uploads
const s3Client = new S3Client({ region: process.env.AWS_REGION });

// Create a new cove
// This endpoint handles cove creation with the following requirements:
// 1. User must be authenticated
// 2. User must be verified
// 3. Name and location are required
// 4. Optional cover photo will be uploaded to S3
export const handleCreateCove = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only POST is allowed
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for creating coves.'
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

    // Check if user is verified - only verified users can create coves
    const prisma = await initializeDatabase();
    const userRecord = await prisma.user.findUnique({
      where: { id: user.uid }
    });

    if (!userRecord?.verified) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Only verified users can create coves'
        })
      };
    }

    // Parse and validate request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    // Extract required and optional fields from request body
    const { name, description, location, coverPhoto } = JSON.parse(event.body);

    // Validate required fields
    if (!name || !location) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Cove name and location are required fields'
        })
      };
    }

    // Create the cove in the database
    const cove = await prisma.cove.create({
      data: {
        name,
        description: description || null,
        location,
        creatorId: user.uid,
      }
    });

    // Handle cover photo upload if provided
    if (coverPhoto) {
      // Create a record for the cover photo in the database
      const coveImage = await prisma.coveImage.create({
        data: {
          coveId: cove.id
        }
      });

      // Get S3 bucket name from environment variables
      const bucketName = process.env.COVE_IMAGE_BUCKET_NAME;
      if (!bucketName) {
        throw new Error('COVE_IMAGE_BUCKET_NAME environment variable is not set');
      }

      // Prepare image for S3 upload
      const s3Key = `${cove.id}/${coveImage.id}.jpg`;
      const imageBuffer = Buffer.from(coverPhoto, 'base64');

      // Upload image to S3
      const command = new PutObjectCommand({
        Bucket: bucketName,
        Key: s3Key,
        Body: imageBuffer,
        ContentType: 'image/jpeg'
      });
      await s3Client.send(command);

      // Update cove with the cover photo reference
      await prisma.cove.update({
        where: { id: cove.id },
        data: { coverPhotoID: coveImage.id }
      });
    }

    // Automatically add the creator as an admin member of the cove
    await prisma.coveMember.create({
      data: {
        coveId: cove.id,
        userId: user.uid,
        role: 'ADMIN'
      }
    });

    // Return success response with cove details
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Cove created successfully',
        cove: {
          id: cove.id,
          name: cove.name,
          description: cove.description,
          location: cove.location,
          createdAt: cove.createdAt
        }
      })
    };
    console.log('Create cove response:', response);
    return response;
  } catch (error) {
    // Handle any errors that occur during cove creation
    console.error('Create cove route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing create cove request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('Create cove error response:', errorResponse);
    return errorResponse;
  }
};

/**
 * Get cove information
 * 
 * This endpoint handles retrieving cove information with the following requirements:
 * 1. User must be authenticated
 * 2. User must be a member of the cove
 * 
 * The endpoint returns:
 * - Basic cove information (id, name, description, location)
 * - Creator information (id, name)
 * - Cover photo URL if one exists
 * - Statistics (member count, event count)
 * 
 * Error cases:
 * - 400: Missing coveId parameter
 * - 403: User is not a member of the cove
 * - 404: Cove not found
 * - 405: Invalid HTTP method
 * - 500: Server error
 */
export const handleGetCove = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving cove information.'
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

    // Get coveId from query parameters
    const coveId = event.queryStringParameters?.coveId;
    if (!coveId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Cove ID is required'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Check if user is a member of the cove
    // This is done before fetching cove details to prevent unauthorized access
    const userMembership = await prisma.coveMember.findUnique({
      where: {
        coveId_userId: {
          coveId,
          userId: user.uid
        }
      }
    });

    if (!userMembership) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'You must be a member of this cove to view its information'
        })
      };
    }

    // Get cove information including:
    // - Basic details (name, description, location)
    // - Cover photo reference
    // - Creator information
    // - Member and event counts
    const cove = await prisma.cove.findUnique({
      where: { id: coveId },
      include: {
        coverPhoto: {
          select: {
            id: true
          }
        },
        createdBy: {
          select: {
            id: true,
            name: true
          }
        },
        _count: {
          select: {
            members: true,
            events: true
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

    // Generate cover photo URL if it exists
    const coverPhoto = cove.coverPhoto ? {
      id: cove.coverPhoto.id,
      url: await getSignedUrl(s3Client, new GetObjectCommand({
        Bucket: process.env.COVE_IMAGE_BUCKET_NAME,
        Key: `${cove.id}/${cove.coverPhoto.id}.jpg`
      }), { expiresIn: 3600 })
    } : null;

    // Return success response with cove information
    return {
      statusCode: 200,
      body: JSON.stringify({
        cove: {
          id: cove.id,
          name: cove.name,
          description: cove.description,
          location: cove.location,
          createdAt: cove.createdAt,
          creator: {
            id: cove.createdBy.id,
            name: cove.createdBy.name
          },
          coverPhoto,
          stats: {
            memberCount: cove._count.members,
            eventCount: cove._count.events
          }
        }
      })
    };
  } catch (error) {
    console.error('Get cove route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get cove request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Get cove members
 * 
 * This endpoint handles retrieving cove members with the following requirements:
 * 1. User must be authenticated
 * 2. User must be a member of the cove
 * 
 * The endpoint returns:
 * - Paginated list of cove members
 * - Each member's basic information (id, name, profile photo)
 * - Member's role in the cove (MEMBER or ADMIN)
 * - When they joined the cove
 * 
 * Error cases:
 * - 400: Missing coveId parameter
 * - 403: User is not a member of the cove
 * - 405: Invalid HTTP method
 * - 500: Server error
 */
export const handleGetCoveMembers = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving cove members.'
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

    // Get coveId from query parameters
    const coveId = event.queryStringParameters?.coveId;
    if (!coveId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Cove ID is required'
        })
      };
    }

    // Get pagination parameters
    // cursor: ID of the last member from previous request (for pagination)
    // limit: number of members to return (defaults to 10, max 50)
    const cursor = event.queryStringParameters?.cursor;
    const requestedLimit = parseInt(event.queryStringParameters?.limit || '10');
    const limit = Math.min(requestedLimit, 50); // Enforce maximum limit of 50

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Check if user is a member of the cove
    // This is done before fetching member list to prevent unauthorized access
    const userMembership = await prisma.coveMember.findUnique({
      where: {
        coveId_userId: {
          coveId,
          userId: user.uid
        }
      }
    });

    if (!userMembership) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'You must be a member of this cove to view its members'
        })
      };
    }

    // Get cove members with pagination
    // We fetch limit + 1 items to determine if there are more results
    const members = await prisma.coveMember.findMany({
      where: { coveId },
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
      // Order by most recent members first
      orderBy: {
        joinedAt: 'desc'
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
    const hasMore = members.length > limit;
    // Remove the extra item we fetched if there are more results
    const membersToReturn = hasMore ? members.slice(0, -1) : members;

    // Return success response with members and pagination info
    return {
      statusCode: 200,
      body: JSON.stringify({
        members: await Promise.all(membersToReturn.map(async member => {
          // Generate profile photo URL if it exists
          const profilePhotoUrl = member.user.profilePhoto ? 
            await getSignedUrl(s3Client, new GetObjectCommand({
              Bucket: process.env.USER_IMAGE_BUCKET_NAME,
              Key: `${member.user.id}/${member.user.profilePhoto.id}.jpg`
            }), { expiresIn: 3600 }) : 
            null;

          return {
            id: member.user.id,
            name: member.user.name,
            profilePhotoUrl,
            role: member.role,
            joinedAt: member.joinedAt
          };
        })),
        pagination: {
          hasMore,
          nextCursor: hasMore ? members[members.length - 2].id : null
        }
      })
    };
  } catch (error) {
    console.error('Get cove members route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get cove members request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Get user's coves
 * 
 * This endpoint handles retrieving all coves that a user is a member of.
 * 
 * The endpoint returns:
 * - List of coves with basic information (id, name, cover photo)
 * 
 * Error cases:
 * - 405: Invalid HTTP method
 * - 500: Server error
 */
export const handleGetUserCoves = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving user coves.'
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

    // Get all coves where the user is a member
    const userCoves = await prisma.coveMember.findMany({
      where: { userId: user.uid },
      include: {
        cove: {
          include: {
            coverPhoto: {
              select: {
                id: true
              }
            }
          }
        }
      }
    });

    // Generate signed URLs for cover photos and format response
    const coves = await Promise.all(userCoves.map(async ({ cove }) => {
      const coverPhoto = cove.coverPhoto ? {
        id: cove.coverPhoto.id,
        url: await getSignedUrl(s3Client, new GetObjectCommand({
          Bucket: process.env.COVE_IMAGE_BUCKET_NAME,
          Key: `${cove.id}/${cove.coverPhoto.id}.jpg`
        }), { expiresIn: 3600 })
      } : null;

      return {
        id: cove.id,
        name: cove.name,
        coverPhoto
      };
    }));

    // Return success response with user's coves
    return {
      statusCode: 200,
      body: JSON.stringify({
        coves
      })
    };
  } catch (error) {
    console.error('Get user coves route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get user coves request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Join a cove
 * 
 * This endpoint handles joining a cove with the following requirements:
 * 1. User must be authenticated
 * 2. Cove must exist
 * 3. User must not already be a member of the cove
 * 
 * The endpoint returns:
 * - Success message
 * - Member information (id, role, joinedAt)
 * 
 * Error cases:
 * - 400: Missing coveId parameter
 * - 403: User already a member
 * - 404: Cove not found
 * - 405: Invalid HTTP method
 * - 500: Server error
 */
export const handleJoinCove = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only POST is allowed
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for joining a cove.'
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

    // Extract required fields from request body
    const { coveId } = JSON.parse(event.body);

    // Validate required fields
    if (!coveId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Cove ID is required'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // TODO: Consider adding user verification requirement in the future
    // Currently, any authenticated user can join coves
    // This could be changed to require verification for joining certain coves

    // Check if cove exists
    const cove = await prisma.cove.findUnique({
      where: { id: coveId }
    });

    if (!cove) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Cove not found'
        })
      };
    }

    // Check if user is already a member of the cove
    const existingMembership = await prisma.coveMember.findUnique({
      where: {
        coveId_userId: {
          coveId: coveId,
          userId: user.uid
        }
      }
    });

    if (existingMembership) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'You are already a member of this cove'
        })
      };
    }

    // Add user as a member of the cove
    const newMembership = await prisma.coveMember.create({
      data: {
        coveId: coveId,
        userId: user.uid,
        role: 'MEMBER' // Default role for new members
      }
    });

    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Successfully joined the cove',
        member: {
          id: newMembership.id,
          coveId: newMembership.coveId,
          userId: newMembership.userId,
          role: newMembership.role,
          joinedAt: newMembership.joinedAt
        }
      })
    };
  } catch (error) {
    console.error('Join cove route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing join cove request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

 // TODO: send invite endpoint 
 // Only admin of the cove can send invites for that cove 

 // TODO: later, request to join a cove endpoint and an approve request endpoint 
 // only admin of the cove can approve requests 
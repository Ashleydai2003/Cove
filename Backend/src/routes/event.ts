import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

// Initialize S3 client for image uploads
const s3Client = new S3Client({ region: process.env.AWS_REGION });

// Create a new event
// This endpoint handles event creation with the following requirements:
// 1. User must be authenticated
// 2. User must be either the cove creator or an admin
// 3. Name, date, location, and coveId are required
// 4. Optional cover photo will be uploaded to S3
export const handleCreateEvent = async (request: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only POST is allowed
    if (request.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for creating events.'
        })
      };
    }

    // Authenticate the request using Firebase
    const authResult = await authMiddleware(request);
    
    // If auth failed, return the error response
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Get the authenticated user's info from Firebase
    const user = authResult.user;
    console.log('Authenticated user:', user.uid);

    // Parse and validate request body
    if (!request.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    // Extract required and optional fields from request body
    const { 
      name, 
      description, 
      date, 
      location,
      coverPhoto,
      coveId 
    } = JSON.parse(request.body);

    // Validate all required fields are present
    if (!name || !date || !coveId || !location) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Name, date, location, and coveId are required fields'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Check if user is an admin of the cove or the cove creator
    const cove = await prisma.cove.findUnique({
      where: { id: coveId },
      include: {
        members: {
          where: { userId: user.uid }
        }
      }
    });

    // Check if the cove exists in the database
    // This prevents creating events for non-existent coves and provides a clear 404 error
    // Example: if someone tries to create an event with coveId: "non-existent-id"
    if (!cove) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Cove not found'
        })
      };
    }

    // Check user's permission level in the cove
    const isCreator = cove.creatorId === user.uid;
    const isAdmin = cove.members[0]?.role === 'ADMIN';

    // Only cove creators and admins can create events
    if (!isCreator && !isAdmin) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Only cove creators and admins can create events'
        })
      };
    }

    // Create the event in the database
    const newEvent = await prisma.event.create({
      data: {
        name,
        description: description || null,
        date: new Date(date),
        location,
        coveId,
        hostId: user.uid,
      }
    });

    // Handle cover photo upload if provided
    if (coverPhoto) {
      // Create a record for the cover photo in the database
      const eventImage = await prisma.eventImage.create({
        data: {
          eventId: newEvent.id
        }
      });

      // Get S3 bucket name from environment variables
      const bucketName = process.env.EVENT_IMAGE_BUCKET_NAME;
      if (!bucketName) {
        throw new Error('EVENT_IMAGE_BUCKET_NAME environment variable is not set');
      }

      // Prepare image for S3 upload
      const s3Key = `${newEvent.id}/${eventImage.id}.jpg`;
      const imageBuffer = Buffer.from(coverPhoto, 'base64');

      // Upload image to S3
      const command = new PutObjectCommand({
        Bucket: bucketName,
        Key: s3Key,
        Body: imageBuffer,
        ContentType: 'image/jpeg'
      });
      await s3Client.send(command);

      // Update event with the cover photo reference
      await prisma.event.update({
        where: { id: newEvent.id },
        data: { coverPhotoID: eventImage.id }
      });
    }

    // Return success response with event details
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Event created successfully',
        event: {
          id: newEvent.id,
          name: newEvent.name,
          description: newEvent.description,
          date: newEvent.date,
          location: newEvent.location,
          coveId: newEvent.coveId,
          createdAt: newEvent.createdAt
        }
      })
    };
    console.log('Create event response:', response);
    return response;
  } catch (error) {
    // Handle any errors that occur during event creation
    console.error('Create event route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing create event request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('Create event error response:', errorResponse);
    return errorResponse;
  }
};

// Get events for a specific cove with pagination
// This endpoint handles retrieving events for a specific cove with the following requirements:
// 1. User must be authenticated
// 2. User must be a member of the cove
// 3. Events are returned with pagination using cursor-based approach
// 4. Each event includes the user's RSVP status
export const handleGetCoveEvents = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving cove events.'
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
    // This query also verifies that the cove exists
    const cove = await prisma.cove.findUnique({
      where: { id: coveId },
      include: {
        members: {
          where: { userId: user.uid }
        }
      }
    });

    // Check if the cove exists and user is a member
    if (!cove) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Cove not found'
        })
      };
    }

    if (cove.members.length === 0) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'You must be a member of this cove to view its events'
        })
      };
    }

    // Get pagination parameters from query string
    // cursor: ID of the last event from previous request (for pagination)
    // limit: number of events to return (defaults to 10, max 50)
    const cursor = event.queryStringParameters?.cursor;
    const requestedLimit = parseInt(event.queryStringParameters?.limit || '10');
    const limit = Math.min(requestedLimit, 50); // Enforce maximum limit of 50

    // Get events with pagination
    // We fetch limit + 1 items to determine if there are more results
    const events = await prisma.event.findMany({
      where: {
        coveId: coveId
      },
      include: {
        // Filter RSVPs to only include the current user's RSVP
        // Since a user can only have one RSVP per event (due to unique constraint),
        // this will return an array with at most one item
        rsvps: {
          where: {
            userId: user.uid
          }
        },
        hostedBy: {
          select: {
            id: true,
            name: true
          }
        },
        // Include cover photo information
        coverPhoto: {
          select: {
            id: true
          }
        }
      },
      // Order events by date ascending (earliest first)
      orderBy: {
        date: 'asc'
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
    const hasMore = events.length > limit;
    // Remove the extra item we fetched if there are more results
    const eventsToReturn = hasMore ? events.slice(0, -1) : events;

    // Return success response with events and pagination info
    return {
      statusCode: 200,
      body: JSON.stringify({
        events: eventsToReturn.map(event => {
          // Get the user's RSVP status
          // event.rsvps[0] is the current user's RSVP because:
          // 1. We filtered RSVPs to only include the current user's RSVP
          // 2. A user can only have one RSVP per event (due to unique constraint)
          const userRsvp = event.rsvps[0];
          
          // Construct cover photo URL if it exists
          const coverPhoto = event.coverPhoto ? {
            id: event.coverPhoto.id,
            url: `${process.env.EVENT_IMAGE_BUCKET_URL}/${event.id}/${event.coverPhoto.id}.jpg`
          } : null;
          
          return {
            id: event.id,
            name: event.name,
            description: event.description,
            date: event.date,
            location: event.location,
            coveId: event.coveId,
            hostId: event.hostId,
            hostName: event.hostedBy.name,
            // Return the user's RSVP status or null if they haven't RSVP'd
            rsvpStatus: userRsvp?.status || null,
            createdAt: event.createdAt,
            coverPhoto: coverPhoto
          };
        }),
        pagination: {
          hasMore,
          // If there are more results, use the last item's ID as the next cursor
          nextCursor: hasMore ? events[events.length - 2].id : null
        }
      })
    };
  } catch (error) {
    console.error('Get cove events route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get cove events request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// Get all events for a user's calendar (events from coves they're members of)
// This endpoint handles retrieving all events from coves the user is a member of with the following requirements:
// 1. User must be authenticated
// 2. Events are returned with pagination using cursor-based approach
// 3. Each event includes the user's RSVP status and cove information
export const handleGetCalendarEvents = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving calendar events.'
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

    // Get pagination parameters from query string
    // cursor: ID of the last event from previous request (for pagination)
    // limit: number of events to return (defaults to 10, max 50)
    const cursor = event.queryStringParameters?.cursor;
    const requestedLimit = parseInt(event.queryStringParameters?.limit || '10');
    const limit = Math.min(requestedLimit, 50); // Enforce maximum limit of 50

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Get events from all coves the user is a member of
    // We fetch limit + 1 items to determine if there are more results
    const events = await prisma.event.findMany({
      where: {
        cove: {
          members: {
            some: {
              userId: user.uid
            }
          }
        }
      },
      include: {
        // Only get RSVPs for the current user to return their status
        rsvps: {
          where: {
            userId: user.uid
          }
        },
        // Include host information (id and name)
        hostedBy: {
          select: {
            id: true,
            name: true
          }
        },
        // Include cove information (id and name)
        cove: {
          select: {
            id: true,
            name: true
          }
        },
        // Include cover photo information
        coverPhoto: {
          select: {
            id: true
          }
        }
      },
      // Order events by date ascending (earliest first)
      orderBy: {
        date: 'asc'
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
    const hasMore = events.length > limit;
    // Remove the extra item we fetched if there are more results
    const eventsToReturn = hasMore ? events.slice(0, -1) : events;

    // Return success response with events and pagination info
    return {
      statusCode: 200,
      body: JSON.stringify({
        events: eventsToReturn.map(event => {
          // Get the user's RSVP status
          const userRsvp = event.rsvps[0];
          
          // Construct cover photo URL if it exists
          const coverPhoto = event.coverPhoto ? {
            id: event.coverPhoto.id,
            url: `${process.env.EVENT_IMAGE_BUCKET_URL}/${event.id}/${event.coverPhoto.id}.jpg`
          } : null;
          
          return {
            id: event.id,
            name: event.name,
            description: event.description,
            date: event.date,
            location: event.location,
            coveId: event.coveId,
            coveName: event.cove.name,
            hostId: event.hostId,
            hostName: event.hostedBy.name,
            // Return the current user's RSVP status (GOING, MAYBE, NOT_GOING) or null if they haven't RSVP'd
            rsvpStatus: userRsvp?.status || null,
            createdAt: event.createdAt,
            coverPhoto: coverPhoto
          };
        }),
        pagination: {
          hasMore,
          // If there are more results, use the last item's ID as the next cursor
          nextCursor: hasMore ? events[events.length - 2].id : null
        }
      })
    };
  } catch (error) {
    console.error('Get calendar events route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get calendar events request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

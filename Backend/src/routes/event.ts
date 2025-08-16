import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { s3Client } from '../config/s3';
import { sendToUserIds } from '../services/notify';

// Create a new event
// This endpoint handles event creation with the following requirements:
// 1. User must be authenticated
// 2. User must be a member of the cove
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

    // Check if user is a member of the cove
    const cove = await prisma.cove.findUnique({
      where: { id: coveId },
      include: {
        members: true
      }
    });

    // Check if the cove exists in the database
    if (!cove) {
      return { statusCode: 404, body: JSON.stringify({ message: 'Cove not found' }) };
    }

    // Check if user is a member of the cove
    const isMember = cove.members.some(m => m.userId === user.uid);
    if (!isMember) {
      return { statusCode: 403, body: JSON.stringify({ message: 'You must be a member of this cove to create events' }) };
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

    // Automatically create a "GOING" RSVP for the event host
    await prisma.eventRSVP.create({ data: { eventId: newEvent.id, userId: user.uid, status: 'GOING' } });

    // Notify cove members (excluding host)
    const recipientUserIds = cove.members.map(m => m.userId).filter(uid => uid !== user.uid);
    if (recipientUserIds.length > 0) {
      await sendToUserIds(
        prisma,
        recipientUserIds,
        'New event in your cove',
        `${name} at ${location}`,
        { type: 'cove_event_created', cove_id: coveId, event_id: newEvent.id }
      );
    }

    // Handle cover photo upload if provided
    if (coverPhoto) {
      const eventImage = await prisma.eventImage.create({ data: { eventId: newEvent.id } });
      const bucketName = process.env.EVENT_IMAGE_BUCKET_NAME;
      if (!bucketName) throw new Error('EVENT_IMAGE_BUCKET_NAME environment variable is not set');
      const s3Key = `${newEvent.id}/${eventImage.id}.jpg`;
      const imageBuffer = Buffer.from(coverPhoto, 'base64');
      const command = new PutObjectCommand({ Bucket: bucketName, Key: s3Key, Body: imageBuffer, ContentType: 'image/jpeg' });
      await s3Client.send(command);
      await prisma.event.update({ where: { id: newEvent.id }, data: { coverPhotoID: eventImage.id } });
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
    console.error('Create event route error:', error);
    const errorResponse = { statusCode: 500, body: JSON.stringify({ message: 'Error processing create event request', error: error instanceof Error ? error.message : 'Unknown error' }) };
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
        // Include cove information with cover photo
        cove: {
          select: {
            id: true,
            name: true,
            coverPhotoID: true
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

    // Get S3 bucket URL from environment variables
    const bucketUrl = process.env.EVENT_IMAGE_BUCKET_URL;
    if (!bucketUrl) {
      throw new Error('EVENT_IMAGE_BUCKET_URL environment variable is not set');
    }

    // Return success response with events and pagination info
    return {
      statusCode: 200,
      body: JSON.stringify({
        events: await Promise.all(eventsToReturn.map(async event => {
          // Get the user's RSVP status (will be "GOING" for RSVP'd events, may be null for hosted events)
          const userRsvp = event.rsvps[0];
          
          // Count RSVPs with "GOING" status for this event
          const goingCount = await prisma.eventRSVP.count({
            where: {
              eventId: event.id,
              status: 'GOING'
            }
          });
          
          // Construct cover photo URL if it exists
          const coverPhoto = event.coverPhoto ? {
            id: event.coverPhoto.id,
            url: await getSignedUrl(s3Client, new GetObjectCommand({
              Bucket: process.env.EVENT_IMAGE_BUCKET_NAME,
              Key: `${event.id}/${event.coverPhoto.id}.jpg`
            }), { expiresIn: 3600 })
          } : null;
          
          // Generate cove cover photo URL if it exists
          const coveCoverPhoto = event.cove.coverPhotoID ? {
            id: event.cove.coverPhotoID,
            url: await getSignedUrl(s3Client, new GetObjectCommand({
              Bucket: process.env.COVE_IMAGE_BUCKET_NAME,
              Key: `${event.cove.id}/${event.cove.coverPhotoID}.jpg`
            }), { expiresIn: 3600 })
          } : null;
          
          return {
            id: event.id,
            name: event.name,
            description: event.description,
            date: event.date,
            location: event.location,
            coveId: event.coveId,
            coveName: event.cove.name,
            coveCoverPhoto: coveCoverPhoto,
            hostId: event.hostId,
            hostName: event.hostedBy.name,
            rsvpStatus: userRsvp?.status || 'NOT_GOING',
            goingCount: goingCount,
            createdAt: event.createdAt,
            coverPhoto: coverPhoto
          };
        })),
        pagination: {
          hasMore,
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

// TODO: handleGetUpcomingEvents has been moved to feed.ts

// Get a specific event by ID
// This endpoint handles retrieving a specific event with the following requirements:
// 1. User must be authenticated
// 2. User must be a member of the event's cove
// 3. Returns all event details including host info, cove info, and user's RSVP status
export const handleGetEvent = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving event details.'
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

    // Get eventId from path parameters
    const eventId = event.queryStringParameters?.eventId;
    if (!eventId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Event ID is required'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Get event with all related data
    const eventData = await prisma.event.findUnique({
      where: { id: eventId },
      include: {
        // Include host information
        hostedBy: {
          select: {
            id: true,
            name: true
          }
        },
        // Include cove information with cover photo
        cove: {
          select: {
            id: true,
            name: true,
            coverPhotoID: true,
            members: {
              where: { userId: user.uid }
            }
          }
        },
        // Include all RSVPs for the event
        rsvps: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                profilePhotoID: true
              }
            }
          }
        },
        // Include cover photo information
        coverPhoto: {
          select: {
            id: true
          }
        }
      }
    });

    // Check if event exists
    if (!eventData) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Event not found'
        })
      };
    }

    // Check if user is a member of the cove
    if (eventData.cove.members.length === 0) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'You must be a member of this cove to view its events'
        })
      };
    }

    // Get the user's RSVP status
    const userRsvp = eventData.rsvps.find(rsvp => rsvp.userId === user.uid);
    
    // Generate cover photo URL if it exists
    const coverPhoto = eventData.coverPhoto ? {
      id: eventData.coverPhoto.id,
      url: await getSignedUrl(s3Client, new GetObjectCommand({
        Bucket: process.env.EVENT_IMAGE_BUCKET_NAME,
        Key: `${eventData.id}/${eventData.coverPhoto.id}.jpg`
      }), { expiresIn: 3600 })
    } : null;

    // Generate cove cover photo URL if it exists
    const coveCoverPhoto = eventData.cove.coverPhotoID ? {
      id: eventData.cove.coverPhotoID,
      url: await getSignedUrl(s3Client, new GetObjectCommand({
        Bucket: process.env.COVE_IMAGE_BUCKET_NAME,
        Key: `${eventData.cove.id}/${eventData.cove.coverPhotoID}.jpg`
      }), { expiresIn: 3600 })
    } : null;

    // Return success response with event details
    return {
      statusCode: 200,
      body: JSON.stringify({
        event: {
          id: eventData.id,
          name: eventData.name,
          description: eventData.description,
          date: eventData.date,
          location: eventData.location,
          coveId: eventData.coveId,
          host: {
            id: eventData.hostedBy.id,
            name: eventData.hostedBy.name
          },
          cove: {
            id: eventData.cove.id,
            name: eventData.cove.name,
            coverPhoto: coveCoverPhoto
          },
          rsvpStatus: userRsvp?.status || 'NOT_GOING',
          rsvps: await Promise.all(eventData.rsvps.map(async rsvp => {
            // Generate profile photo URL if it exists
            const profilePhotoUrl = rsvp.user.profilePhotoID ? 
              await getSignedUrl(s3Client, new GetObjectCommand({
                Bucket: process.env.USER_IMAGE_BUCKET_NAME,
                Key: `${rsvp.user.id}/${rsvp.user.profilePhotoID}.jpg`
              }), { expiresIn: 3600 }) : 
              null;

            return {
              id: rsvp.id,
              status: rsvp.status,
              userId: rsvp.userId,
              userName: rsvp.user.name,
              profilePhotoUrl: profilePhotoUrl,
              createdAt: rsvp.createdAt
            };
          })),
          coverPhoto,
          isHost: eventData.hostId === user.uid
        }
      })
    };
  } catch (error) {
    console.error('Get event route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get event request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// Update RSVP (notify host when someone RSVPs GOING)
export const handleUpdateEventRSVP = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    if (event.httpMethod !== 'POST') {
      return { statusCode: 405, body: JSON.stringify({ message: 'Method not allowed. Only POST requests are accepted for updating RSVP status.' }) };
    }
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) { return authResult; }
    const user = authResult.user;

    if (!event.body) {
      return { statusCode: 400, body: JSON.stringify({ message: 'Request body is required' }) };
    }
    const { eventId, status } = JSON.parse(event.body);
    if (!eventId || !status) { return { statusCode: 400, body: JSON.stringify({ message: 'Event ID and RSVP status are required' }) }; }
    if (!['GOING', 'MAYBE', 'NOT_GOING'].includes(status)) { return { statusCode: 400, body: JSON.stringify({ message: 'Invalid RSVP status. Must be one of: GOING, MAYBE, NOT_GOING' }) }; }

    const prisma = await initializeDatabase();
    const eventData = await prisma.event.findUnique({ where: { id: eventId }, select: { id: true, coveId: true, hostId: true, name: true, location: true } });
    if (!eventData) { return { statusCode: 404, body: JSON.stringify({ message: 'Event not found' }) }; }

    // Ensure user is a member of the cove
    const membership = await prisma.coveMember.findFirst({ where: { coveId: eventData.coveId, userId: user.uid } });
    if (!membership) { return { statusCode: 403, body: JSON.stringify({ message: 'You must be a member of this cove to RSVP to its events' }) }; }

    const rsvp = await prisma.eventRSVP.upsert({
      where: { eventId_userId: { eventId, userId: user.uid } },
      update: { status },
      create: { eventId, userId: user.uid, status }
    });

    // Notify host when someone RSVPs GOING
    if (status === 'GOING' && eventData.hostId !== user.uid) {
      const rsvpUser = await prisma.user.findUnique({ where: { id: user.uid }, select: { name: true } });
      await sendToUserIds(
        prisma,
        [eventData.hostId],
        'New RSVP to your event',
        `${rsvpUser?.name || 'Someone'} is going to ${eventData.name}`,
        { type: 'cove_event_rsvp', cove_id: eventData.coveId, event_id: eventData.id }
      );
    }

    return { statusCode: 200, body: JSON.stringify({ message: 'RSVP status updated successfully', rsvp: { id: rsvp.id, status: rsvp.status, eventId: rsvp.eventId, userId: rsvp.userId, createdAt: rsvp.createdAt } }) };
  } catch (error) {
    console.error('Update RSVP route error:', error);
    return { statusCode: 500, body: JSON.stringify({ message: 'Error processing RSVP update request', error: error instanceof Error ? error.message : 'Unknown error' }) };
  }
};

// TODO: In the future, consider handling MAYBE responses as well for a more comprehensive calendar view
// Get events that the user has RSVP'd "GOING" to OR is hosting (for calendar view)
// This endpoint handles retrieving events the user has committed to attend or is hosting with the following requirements:
// 1. User must be authenticated
// 2. Returns events where user RSVP status is "GOING" OR user is the host
// 3. Events are returned with pagination using cursor-based approach
// 4. Each event includes the user's RSVP status and cove information
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

    // Get events where the user has RSVP'd "GOING" OR is the host
    // We fetch limit + 1 items to determine if there are more results
    const events = await prisma.event.findMany({
      where: {
        OR: [
          // Events where user RSVP'd "GOING"
          {
            rsvps: {
              some: {
                userId: user.uid,
                status: 'GOING'
              }
            }
          },
          // Events where user is the host
          {
            hostId: user.uid
          }
        ]
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
        // Include cove information (id, name, and cover photo)
        cove: {
          select: {
            id: true,
            name: true,
            coverPhotoID: true
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

    // Get S3 bucket URL from environment variables
    const bucketUrl = process.env.EVENT_IMAGE_BUCKET_URL;
    if (!bucketUrl) {
      throw new Error('EVENT_IMAGE_BUCKET_URL environment variable is not set');
    }

    // Return success response with events and pagination info
    return {
      statusCode: 200,
      body: JSON.stringify({
        events: await Promise.all(eventsToReturn.map(async event => {
          // Get the user's RSVP status (will be "GOING" for RSVP'd events, may be null for hosted events)
          const userRsvp = event.rsvps[0];
          
          // Count RSVPs with "GOING" status for this event
          const goingCount = await prisma.eventRSVP.count({
            where: {
              eventId: event.id,
              status: 'GOING'
            }
          });
          
          // Generate cover photo URL if it exists
          const coverPhoto = event.coverPhoto ? {
            id: event.coverPhoto.id,
            url: await getSignedUrl(s3Client, new GetObjectCommand({
              Bucket: process.env.EVENT_IMAGE_BUCKET_NAME,
              Key: `${event.id}/${event.coverPhoto.id}.jpg`
            }), { expiresIn: 3600 })
          } : null;
          
          // Generate cove cover photo URL if it exists
          const coveCoverPhoto = event.cove.coverPhotoID ? {
            id: event.cove.coverPhotoID,
            url: await getSignedUrl(s3Client, new GetObjectCommand({
              Bucket: process.env.COVE_IMAGE_BUCKET_NAME,
              Key: `${event.cove.id}/${event.cove.coverPhotoID}.jpg`
            }), { expiresIn: 3600 })
          } : null;
          
          return {
            id: event.id,
            name: event.name,
            description: event.description,
            date: event.date,
            location: event.location,
            coveId: event.coveId,
            coveName: event.cove.name,
            coveCoverPhoto: coveCoverPhoto,
            hostId: event.hostId,
            hostName: event.hostedBy.name,
            rsvpStatus: userRsvp?.status || 'NOT_GOING',
            goingCount: goingCount,
            createdAt: event.createdAt,
            coverPhoto
          };
        })),
        pagination: {
          hasMore,
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

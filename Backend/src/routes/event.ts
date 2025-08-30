import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { s3Client } from '../config/s3';
import * as admin from 'firebase-admin';

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
      memberCap,
      ticketPrice,
      paymentHandle,
      isPublic,
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

    // Validate optional numeric fields if provided
    if (memberCap !== undefined && memberCap !== null && (!Number.isInteger(memberCap) || memberCap < 1)) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Member cap must be a positive integer if provided'
        })
      };
    }

    if (ticketPrice !== undefined && ticketPrice !== null && (typeof ticketPrice !== 'number' || ticketPrice < 0)) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Ticket price must be a non-negative number if provided'
        })
      };
    }

    // Validate isPublic if provided
    if (isPublic !== undefined && typeof isPublic !== 'boolean') {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'isPublic must be a boolean if provided'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Check if user is a member of the cove
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

    // Check if user is a member of the cove
    // Any member of a cove can create events for that cove
    if (cove.members.length === 0) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'You must be a member of this cove to create events'
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
        memberCap: memberCap || null,
        ticketPrice: ticketPrice || null,
        paymentHandle: paymentHandle || null,
        isPublic: isPublic === true,
        coveId,
        hostId: user.uid,
      }
    });

    // Automatically create a "GOING" RSVP for the event host
    // This ensures the host automatically appears in their own calendar
    await prisma.eventRSVP.create({
      data: {
        eventId: newEvent.id,
        userId: user.uid,
        status: 'GOING'
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
          memberCap: newEvent.memberCap,
          ticketPrice: newEvent.ticketPrice,
          paymentHandle: newEvent.paymentHandle,
          isPublic: newEvent.isPublic,
          coveId: newEvent.coveId,
          createdAt: newEvent.createdAt
        }
      })
    };
    console.log('Create event response:', response);

    // Notify cove members (except creator)
    try {
      const [members, host] = await Promise.all([
        prisma.coveMember.findMany({ where: { coveId }, select: { userId: true, user: { select: { fcmToken: true } } } }),
        prisma.user.findUnique({ where: { id: user.uid }, select: { name: true } })
      ]);
      const hostName = host?.name || 'Someone';
      const coveName = (typeof cove?.name === 'string' && cove?.name) ? cove!.name : 'your cove';
      for (const m of members) {
        if (m.userId === user.uid) continue;
        const token = m.user.fcmToken;
        if (!token) continue;
        try {
          if (process.env.NODE_ENV === 'production') {
            await admin.messaging().send({
              token,
              notification: {
                title: `🎉 ${coveName} just got plans`,
                body: `${hostName} is hosting "${name}"`
              },
              data: {
                type: 'event_created',
                eventId: newEvent.id,
                coveId: coveId
              },
              apns: {
                payload: {
                  aps: {
                    category: 'EVENT_CATEGORY'
                  }
                }
              }
            });
          } else {
            console.log('Skipping push notification in non-production (event created)');
          }
        } catch (err) {
          console.error('Event created notify error:', err);
        }
      }
    } catch (notifyErr) {
      console.error('Event creation notify error:', notifyErr);
    }
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

    // Optional authentication
    const authAttempt = await authMiddleware(event);
    let userUid: string | null = null;
    if (!('statusCode' in authAttempt)) {
      userUid = authAttempt.user.uid;
      console.log('Authenticated user:', userUid);
    }

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

    // TODO(PRIVATE_COVES): This membership check will be implemented later when private coves are supported
    // // Check if user is a member of the cove
    // // This query also verifies that the cove exists
    // const cove = await prisma.cove.findUnique({
    //   where: { id: coveId },
    //   include: {
    //     members: {
    //       where: { userId: user.uid }
    //     }
    //   }
    // });
    //
    // // Check if the cove exists and user is a member
    // if (!cove) {
    //   return {
    //     statusCode: 404,
    //     body: JSON.stringify({
    //       message: 'Cove not found'
    //     })
    //   };
    // }

    // If unauthenticated: return only first 5 limited events, no pagination
    if (!userUid) {
      const events = await prisma.event.findMany({
        where: { coveId },
        include: {
          hostedBy: { select: { id: true, name: true } },
          cove: { select: { id: true, name: true, coverPhotoID: true } },
          coverPhoto: { select: { id: true } }
        },
        orderBy: { date: 'asc' },
        take: 5
      });

      const items = await Promise.all(events.map(async ev => {
        const coverPhoto = ev.coverPhoto ? {
          id: ev.coverPhoto.id,
          url: await getSignedUrl(s3Client, new GetObjectCommand({
            Bucket: process.env.EVENT_IMAGE_BUCKET_NAME,
            Key: `${ev.id}/${ev.coverPhoto.id}.jpg`
          }), { expiresIn: 3600 })
        } : null;

        const coveCoverPhoto = ev.cove.coverPhotoID ? {
          id: ev.cove.coverPhotoID,
          url: await getSignedUrl(s3Client, new GetObjectCommand({
            Bucket: process.env.COVE_IMAGE_BUCKET_NAME,
            Key: `${ev.cove.id}/${ev.cove.coverPhotoID}.jpg`
          }), { expiresIn: 3600 })
        } : null;

        return {
          id: ev.id,
          name: ev.name,
          description: ev.description,
          date: ev.date,
          coveCoverPhoto,
          hostName: ev.hostedBy.name,
          coverPhoto
        };
      }));

      return {
        statusCode: 200,
        headers: {
          'Cache-Control': 'public, max-age=60'
        },
        body: JSON.stringify({ events: items })
      };
    }

    // Pagination params
    const cursor = event.queryStringParameters?.cursor;
    const requestedLimit = parseInt(event.queryStringParameters?.limit || '10');
    const limit = Math.min(requestedLimit, 50);

    // Fetch events with minimal related data (avoid over-fetching)
    const events = await prisma.event.findMany({
      where: { coveId },
      include: {
        hostedBy: { select: { id: true, name: true } },
        cove: { select: { id: true, name: true, coverPhotoID: true } },
        coverPhoto: { select: { id: true } }
      },
      orderBy: { date: 'asc' },
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {})
    });

    const hasMore = events.length > limit;
    const eventsToReturn = hasMore ? events.slice(0, -1) : events;

    // If authenticated, fetch user's RSVPs for the page in one query
    const eventIds = eventsToReturn.map(e => e.id);
    const userRsvps = userUid && eventIds.length > 0 ? await prisma.eventRSVP.findMany({
      where: { userId: userUid, eventId: { in: eventIds } },
      select: { eventId: true, status: true }
    }) : [];
    const eventIdToUserRsvp: Record<string, string> = {};
    for (const r of userRsvps || []) {
      eventIdToUserRsvp[r.eventId] = r.status as string;
    }

    // Build response items; decide per-item whether it's enriched
    let anyEnriched = false;

    const items = await Promise.all(eventsToReturn.map(async ev => {
      const isHost = !!(userUid && ev.hostId === userUid);
      const rsvpStatus = userUid ? eventIdToUserRsvp[ev.id] ?? null : undefined;

      // Signed URLs
      const coverPhoto = ev.coverPhoto ? {
        id: ev.coverPhoto.id,
        url: await getSignedUrl(s3Client, new GetObjectCommand({
          Bucket: process.env.EVENT_IMAGE_BUCKET_NAME,
          Key: `${ev.id}/${ev.coverPhoto.id}.jpg`
        }), { expiresIn: 3600 })
      } : null;

      const coveCoverPhoto = ev.cove.coverPhotoID ? {
        id: ev.cove.coverPhotoID,
        url: await getSignedUrl(s3Client, new GetObjectCommand({
          Bucket: process.env.COVE_IMAGE_BUCKET_NAME,
          Key: `${ev.cove.id}/${ev.cove.coverPhotoID}.jpg`
        }), { expiresIn: 3600 })
      } : null;

      // Enriched item if host or has RSVP
      if (isHost || rsvpStatus) {
        anyEnriched = true;
        // Compute goingCount only for enriched items
        const goingCount = await prisma.eventRSVP.count({
          where: { eventId: ev.id, status: 'GOING' }
        });

        return {
          id: ev.id,
          name: ev.name,
          description: ev.description,
          date: ev.date,
          location: ev.location,
                      memberCap: ev.memberCap,
            ticketPrice: ev.ticketPrice,
            paymentHandle: null, // Not included in cove events list for privacy
            coveId: ev.coveId,
          coveName: ev.cove.name,
          coveCoverPhoto: coveCoverPhoto,
          hostId: ev.hostId,
          hostName: ev.hostedBy.name,
          rsvpStatus: rsvpStatus || null,
          goingCount: goingCount,
          createdAt: ev.createdAt,
          coverPhoto: coverPhoto
        };
      }

      // Limited item otherwise
      const limited: any = {
        id: ev.id,
        name: ev.name,
        description: ev.description,
        date: ev.date,
        coveCoverPhoto: coveCoverPhoto,
        hostName: ev.hostedBy.name,
        coverPhoto: coverPhoto
      };
      if (userUid) {
        limited.rsvpStatus = null;
      }
      return limited;
    }));

    return {
      statusCode: 200,
      headers: anyEnriched ? {
        'Cache-Control': 'private, no-store',
        'Vary': 'Authorization, Cookie'
      } : {
        'Cache-Control': 'public, max-age=60'
      },
      body: JSON.stringify({
        events: items,
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
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving event details.'
        })
      };
    }

    // Optional authentication
    console.log('Request cookies:', event.headers.cookie);
    const authAttempt = await authMiddleware(event);
    let userUid: string | null = null;
    if (!('statusCode' in authAttempt)) {
      userUid = authAttempt.user.uid;
      console.log('Authenticated user:', userUid);
    } else {
      console.log('Authentication failed or no auth token provided');
    }

    const eventId = event.queryStringParameters?.eventId;
    if (!eventId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Event ID is required' })
      };
    }

    const prisma = await initializeDatabase();

    // Minimal fetch first (avoid over-fetching sensitive relations)
    const eventData = await prisma.event.findUnique({
      where: { id: eventId },
      include: {
        hostedBy: { select: { id: true, name: true } },
        cove: { select: { id: true, name: true, coverPhotoID: true } },
        coverPhoto: { select: { id: true } }
      }
    });

    if (!eventData) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Event not found' })
      };
    }

    // Precompute signed URLs
    const coverPhoto = eventData.coverPhoto ? {
      id: eventData.coverPhoto.id,
      url: await getSignedUrl(s3Client, new GetObjectCommand({
        Bucket: process.env.EVENT_IMAGE_BUCKET_NAME,
        Key: `${eventData.id}/${eventData.coverPhoto.id}.jpg`
      }), { expiresIn: 3600 })
    } : null;

    const coveCoverPhoto = eventData.cove.coverPhotoID ? {
      id: eventData.cove.coverPhotoID,
      url: await getSignedUrl(s3Client, new GetObjectCommand({
        Bucket: process.env.COVE_IMAGE_BUCKET_NAME,
        Key: `${eventData.cove.id}/${eventData.cove.coverPhotoID}.jpg`
      }), { expiresIn: 3600 })
    } : null;

    // Determine user relationship without over-fetching
    const isHost = !!(userUid && eventData.hostId === userUid);
    console.log('User relationship check:', { userUid, eventHostId: eventData.hostId, isHost });
    
    const userRsvp = userUid ? await prisma.eventRSVP.findUnique({
      where: { eventId_userId: { eventId: eventData.id, userId: userUid } },
      select: { id: true, status: true, userId: true }
    }) : null;
    
    console.log('User RSVP lookup result:', { userUid, eventId: eventData.id, userRsvp });
    
    // Debug: Let's also check all RSVPs for this event to see what's in the database
    if (userUid) {
      const allRsvps = await prisma.eventRSVP.findMany({
        where: { eventId: eventData.id },
        select: { id: true, status: true, userId: true }
      });
      console.log('All RSVPs for this event:', allRsvps);
      console.log('Looking for user ID:', userUid);
    }

    // If entitled (host OR has GOING status), fetch attendee list and return full details
    // Note: Hosts always get full access to manage their events, regardless of RSVP status
    const hasGoingRsvp = userRsvp && userRsvp.status === 'GOING';
    if (isHost || hasGoingRsvp) {
      const attendees = await prisma.eventRSVP.findMany({
        where: { eventId: eventData.id, status: 'GOING' },
        orderBy: { createdAt: 'desc' },
        take: 5,
        include: {
          user: { select: { id: true, name: true, profilePhotoID: true } }
        }
      });

      // Count RSVPs with "GOING" status for this event
      const goingCount = await prisma.eventRSVP.count({
        where: { eventId: eventData.id, status: 'GOING' }
      });

      // Count RSVPs with "PENDING" status for this event  
      const pendingCount = await prisma.eventRSVP.count({
        where: { eventId: eventData.id, status: 'PENDING' }
      });

      return {
        statusCode: 200,
        headers: {
          'Cache-Control': 'private, no-store',
          'Vary': 'Authorization, Cookie'
        },
        body: JSON.stringify({
          event: {
            id: eventData.id,
            name: eventData.name,
            description: eventData.description,
            date: eventData.date,
            location: eventData.location,
                  memberCap: eventData.memberCap,
      ticketPrice: eventData.ticketPrice,
      paymentHandle: eventData.paymentHandle, // Available to all authenticated users
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
            rsvpStatus: userRsvp?.status || null,
            goingCount: goingCount,
            pendingCount: pendingCount,
            rsvps: await Promise.all(attendees.map(async rsvp => {
              const profilePhotoUrl = rsvp.user.profilePhotoID ?
                await getSignedUrl(s3Client, new GetObjectCommand({
                  Bucket: process.env.USER_IMAGE_BUCKET_NAME,
                  Key: `${rsvp.user.id}/${rsvp.user.profilePhotoID}.jpg`
                }), { expiresIn: 3600 }) : null;
              return {
                id: rsvp.id,
                status: rsvp.status,
                userId: rsvp.userId,
                userName: rsvp.user.name,
                profilePhotoUrl,
                createdAt: rsvp.createdAt
              };
            })),
            coverPhoto,
            isHost
          }
        })
      };
    }

    // Count RSVPs with "GOING" status for this event (for limited response)
    const goingCount = await prisma.eventRSVP.count({
      where: { eventId: eventData.id, status: 'GOING' }
    });

    // Count RSVPs with "PENDING" status for this event (for limited response)
    const pendingCount = await prisma.eventRSVP.count({
      where: { eventId: eventData.id, status: 'PENDING' }
    });

    // Limited response for unauthenticated or authenticated-without-GOING-status/host
    const limitedEvent: any = {
      id: eventData.id,
      name: eventData.name,
      description: eventData.description,
      date: eventData.date,
      memberCap: eventData.memberCap,
      ticketPrice: eventData.ticketPrice,
      paymentHandle: eventData.paymentHandle, // Available to all authenticated users
      host: { name: eventData.hostedBy.name },
      cove: { 
        name: eventData.cove.name,
        coverPhoto: coveCoverPhoto 
      },
      goingCount: goingCount,
      pendingCount: pendingCount,
      coverPhoto
    };

    // Always include rsvpStatus for authenticated users
    if (userUid) {
      limitedEvent.isHost = false;
      limitedEvent.rsvpStatus = userRsvp?.status || null;
      console.log('Limited response for authenticated user:', { 
        userUid, 
        rsvpStatus: limitedEvent.rsvpStatus, 
        userRsvp: userRsvp 
      });
    } else {
      // Unauthenticated users get null rsvpStatus
      limitedEvent.rsvpStatus = null;
    }

    return {
      statusCode: 200,
      headers: {
        'Cache-Control': 'private, no-store'
      },
      body: JSON.stringify({ event: limitedEvent })
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

// Update a user's RSVP status for an event
// This endpoint handles updating RSVP status with the following requirements:
// 1. User must be authenticated
// 2. User must be a member of the event's cove
// 3. Status must be one of: "GOING", "PENDING" 
// 4. When user RSVPs, they get PENDING status and host can approve to GOING
export const handleUpdateEventRSVP = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    console.log('=== BACKEND RSVP UPDATE START ===');
    console.log('Request method:', event.httpMethod);
    console.log('Request path:', event.path);
    console.log('Request headers:', event.headers);
    console.log('Request body:', event.body);
    
    // Validate request method - only POST is allowed
    if (event.httpMethod !== 'POST') {
      console.log('Invalid method:', event.httpMethod);
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for updating RSVP status.'
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
    console.log('Parsing request body...');
    const { eventId, status } = JSON.parse(event.body);
    console.log('Extracted fields:', { eventId, status });

    // Validate required fields
    if (!eventId || !status) {
      console.log('Missing required fields:', { eventId, status });
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Event ID and RSVP status are required'
        })
      };
    }

    // Validate RSVP status
    if (!['GOING', 'PENDING'].includes(status)) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Invalid RSVP status. Must be one of: GOING, PENDING'
        })
      };
    }

    // Initialize database connection
    console.log('Initializing database connection...');
    const prisma = await initializeDatabase();
    console.log('Database connection initialized');

    // Check if user is a member of the event's cove
    console.log('Looking up event:', eventId);
    const eventData = await prisma.event.findUnique({
      where: { id: eventId },
      include: {
        cove: {
          include: {
            members: {
              where: { userId: user.uid }
            }
          }
        }
      }
    });
    console.log('Event data found:', !!eventData);

    // Check if event exists
    if (!eventData) {
      console.log('Event not found:', eventId);
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Event not found'
        })
      };
    }

    // Check if user is a member of the cove (only for private events)
    if (!eventData.isPublic && eventData.cove.members.length === 0) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'You must be a member of this cove to RSVP to its events'
        })
      };
    }

    // Check if user already has an RSVP for this event
    const existingRSVP = await prisma.eventRSVP.findUnique({
      where: {
        eventId_userId: {
          eventId: eventId,
          userId: user.uid
        }
      }
    });

    // If user already has GOING or PENDING status, no action needed
    if (existingRSVP && (existingRSVP.status === 'GOING' || existingRSVP.status === 'PENDING')) {
      const statusMessage = existingRSVP.status === 'GOING' 
        ? 'User is already going to this event'
        : 'User already has a pending RSVP for this event';
      
      return {
        statusCode: 200,
        body: JSON.stringify({
          message: statusMessage,
          rsvp: {
            id: existingRSVP.id,
            status: existingRSVP.status,
            eventId: existingRSVP.eventId,
            userId: existingRSVP.userId,
            createdAt: existingRSVP.createdAt
          }
        })
      };
    }

    // When a user RSVPs, they start with PENDING status (awaiting host approval)
    // Exception: Hosts can automatically approve themselves to GOING status
    const isHost = eventData.hostId === user.uid;
    const finalStatus = isHost ? 'GOING' : 'PENDING';
    console.log('RSVP details:', { isHost, finalStatus, eventHostId: eventData.hostId, userId: user.uid });
    
    // Update or create RSVP using upsert
    let rsvp: any = null;
    let rsvpResponse: any = null;
    
    console.log('Performing RSVP upsert...');
    // Upsert for GOING or PENDING
    rsvp = await prisma.eventRSVP.upsert({
      where: {
        eventId_userId: {
          eventId: eventId,
          userId: user.uid
        }
      },
      update: { status: finalStatus },
      create: { eventId, userId: user.uid, status: finalStatus }
    });
          rsvpResponse = {
        id: rsvp.id,
        status: rsvp.status,
        eventId: rsvp.eventId,
        userId: rsvp.userId,
        createdAt: rsvp.createdAt
      };
      console.log('RSVP upsert successful:', rsvpResponse);

    // Best-effort notify event host about RSVP update
    try {
      const [eventDataFull, rsvper] = await Promise.all([
        prisma.event.findUnique({ where: { id: eventId }, select: { hostId: true, name: true, coveId: true, hostedBy: { select: { fcmToken: true } } } }),
        prisma.user.findUnique({ where: { id: user.uid }, select: { name: true } })
      ]);
      if (eventDataFull && eventDataFull.hostId !== user.uid) {
        const hostToken = eventDataFull.hostedBy?.fcmToken;
        if (hostToken) {
          const rsvperName = rsvper?.name || 'Someone';
          const eventName = eventDataFull.name;
          const statusText = status === 'GOING' ? 'going' : 'pending';
          if (process.env.NODE_ENV === 'production') {
            await admin.messaging().send({
              token: hostToken,
              notification: {
                title: `📅 Attendance update for "${eventName}"`,
                body: `${rsvperName} changed their status to ${statusText}`
              },
              data: {
                type: 'event_rsvp',
                eventId: eventId,
                coveId: eventDataFull.coveId
              }
            });
          } else {
            console.log('Skipping push notification in non-production (event rsvp)');
          }
        }
      }
    } catch (notifyErr) {
      console.error('RSVP notify error:', notifyErr);
    }

    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'RSVP status updated successfully',
        rsvp: rsvpResponse
      })
    };
  } catch (error) {
    console.error('=== BACKEND RSVP UPDATE ERROR ===');
    console.error('Error type:', typeof error);
    console.error('Error message:', error instanceof Error ? error.message : error);
    console.error('Error stack:', error instanceof Error ? error.stack : 'No stack trace');
    console.error('Full error object:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing RSVP update request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// Remove RSVP (when user cancels their RSVP)
export const handleRemoveEventRSVP = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    console.log('=== BACKEND RSVP REMOVAL START ===');
    console.log('Request method:', event.httpMethod);
    console.log('Request path:', event.path);
    console.log('Request headers:', event.headers);
    console.log('Request body:', event.body);
    
    // Validate request method - only POST is allowed
    if (event.httpMethod !== 'POST') {
      console.log('Invalid method:', event.httpMethod);
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for removing RSVP.'
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
    console.log('Parsing request body...');
    const { eventId } = JSON.parse(event.body);
    console.log('Extracted fields:', { eventId });

    // Validate required fields
    if (!eventId) {
      console.log('Missing required fields:', { eventId });
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Event ID is required'
        })
      };
    }

    // Initialize database connection
    console.log('Initializing database connection...');
    const prisma = await initializeDatabase();
    console.log('Database connection initialized');

    // Check if the RSVP exists
    console.log('Looking up existing RSVP...');
    const existingRSVP = await prisma.eventRSVP.findUnique({
      where: {
        eventId_userId: {
          eventId: eventId,
          userId: user.uid
        }
      }
    });

    if (!existingRSVP) {
      console.log('No RSVP found to remove');
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'No RSVP found for this event'
        })
      };
    }

    // Delete the RSVP
    console.log('Deleting RSVP...');
    await prisma.eventRSVP.delete({
      where: {
        eventId_userId: {
          eventId: eventId,
          userId: user.uid
        }
      }
    });

    console.log('RSVP removed successfully');

    // Best-effort notify event host about RSVP removal
    try {
      const [eventDataFull, rsvper] = await Promise.all([
        prisma.event.findUnique({ 
          where: { id: eventId }, 
          select: { 
            hostId: true, 
            name: true, 
            coveId: true, 
            hostedBy: { select: { fcmToken: true } } 
          } 
        }),
        prisma.user.findUnique({ where: { id: user.uid }, select: { name: true } })
      ]);
      
      if (eventDataFull && eventDataFull.hostId !== user.uid) {
        const hostToken = eventDataFull.hostedBy?.fcmToken;
        if (hostToken) {
          const rsvperName = rsvper?.name || 'Someone';
          const eventName = eventDataFull.name;
          
          if (process.env.NODE_ENV === 'production') {
            await admin.messaging().send({
              token: hostToken,
              notification: {
                title: `📅 Attendance update for "${eventName}"`,
                body: `${rsvperName} can no longer make it`
              },
              data: {
                type: 'event_rsvp_removed',
                eventId: eventId,
                coveId: eventDataFull.coveId
              }
            });
          } else {
            console.log('Skipping push notification in non-production (event rsvp removal)');
          }
        }
      }
    } catch (notifyErr) {
      console.error('RSVP removal notify error:', notifyErr);
    }

    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'RSVP removed successfully'
      })
    };
  } catch (error) {
    console.error('=== BACKEND RSVP REMOVAL ERROR ===');
    console.error('Error type:', typeof error);
    console.error('Error message:', error instanceof Error ? error.message : error);
    console.error('Error stack:', error instanceof Error ? error.stack : 'No stack trace');
    console.error('Full error object:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing RSVP removal request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
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
            memberCap: event.memberCap,
            ticketPrice: event.ticketPrice,
            paymentHandle: null, // Not included in calendar events list for privacy
            coveId: event.coveId,
            coveName: event.cove.name,
            coveCoverPhoto: coveCoverPhoto,
            hostId: event.hostId,
            hostName: event.hostedBy.name,
            rsvpStatus: userRsvp?.status || null,
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

// Get event members (GOING status only) - paginated
// This endpoint handles retrieving approved event members with the following requirements:
// 1. User must be authenticated
// 2. User must have GOING status or be the host to see the member list
// 3. Returns paginated list of approved members
export const handleGetEventMembers = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
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

    const userUid = authResult.user.uid;
    const eventId = event.queryStringParameters?.eventId;
    const cursor = event.queryStringParameters?.cursor;
    const limit = Math.min(parseInt(event.queryStringParameters?.limit || '20'), 50);

    if (!eventId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Event ID is required' })
      };
    }

    const prisma = await initializeDatabase();

    // Check if user is entitled to see the member list (host or GOING status)
    const eventData = await prisma.event.findUnique({
      where: { id: eventId },
      select: { hostId: true }
    });

    if (!eventData) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Event not found' })
      };
    }

    const isHost = eventData.hostId === userUid;
    const userRsvp = await prisma.eventRSVP.findUnique({
      where: { eventId_userId: { eventId, userId: userUid } },
      select: { status: true }
    });

    const hasGoingStatus = userRsvp?.status === 'GOING';

    if (!isHost && !hasGoingStatus) {
      return {
        statusCode: 403,
        body: JSON.stringify({ message: 'Access denied. Must be host or have approved RSVP.' })
      };
    }

    // Get approved members with pagination
    const whereClause: any = {
      eventId,
      status: 'GOING'
    };

    if (cursor) {
      whereClause.id = { gt: cursor };
    }

    const members = await prisma.eventRSVP.findMany({
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      include: {
        user: { 
          select: { 
            id: true, 
            name: true, 
            profilePhotoID: true,
            profile: {
              select: {
                almaMater: true,
                gradYear: true
              }
            }
          } 
        }
      }
    });

    const hasMore = members.length > limit;
    const itemsToReturn = hasMore ? members.slice(0, -1) : members;
    const nextCursor = hasMore ? itemsToReturn[itemsToReturn.length - 1].id : null;

    // Generate signed URLs for profile photos
    const membersWithUrls = await Promise.all(
      itemsToReturn.map(async (member) => {
        const profilePhotoUrl = member.user.profilePhotoID
          ? await getSignedUrl(s3Client, new GetObjectCommand({
              Bucket: process.env.USER_IMAGE_BUCKET_NAME,
              Key: `${member.user.id}/${member.user.profilePhotoID}.jpg`
            }), { expiresIn: 3600 })
          : null;

        return {
          id: member.id,
          userId: member.user.id,
          userName: member.user.name,
          profilePhotoUrl,
          joinedAt: member.createdAt,
          school: member.user.profile?.almaMater || null,
          gradYear: member.user.profile?.gradYear || null
        };
      })
    );

    return {
      statusCode: 200,
      headers: {
        'Cache-Control': 'private, no-store'
      },
      body: JSON.stringify({
        members: membersWithUrls,
        hasMore,
        nextCursor
      })
    };
  } catch (error) {
    console.error('Get event members error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error retrieving event members',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// Get pending members (PENDING status only) - host only
// This endpoint handles retrieving pending event members with the following requirements:
// 1. User must be authenticated
// 2. User must be the event host
// 3. Returns paginated list of pending members awaiting approval
export const handleGetPendingMembers = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
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

    const userUid = authResult.user.uid;
    const eventId = event.queryStringParameters?.eventId;
    const cursor = event.queryStringParameters?.cursor;
    const limit = Math.min(parseInt(event.queryStringParameters?.limit || '20'), 50);

    if (!eventId) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Event ID is required' })
      };
    }

    const prisma = await initializeDatabase();

    // Check if user is the event host
    const eventData = await prisma.event.findUnique({
      where: { id: eventId },
      select: { hostId: true }
    });

    if (!eventData) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Event not found' })
      };
    }

    if (eventData.hostId !== userUid) {
      return {
        statusCode: 403,
        body: JSON.stringify({ message: 'Access denied. Only event hosts can view pending members.' })
      };
    }

    // Get pending members with pagination
    const whereClause: any = {
      eventId,
      status: 'PENDING'
    };

    if (cursor) {
      whereClause.id = { gt: cursor };
    }

    const pendingMembers = await prisma.eventRSVP.findMany({
      where: whereClause,
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      include: {
        user: { 
          select: { 
            id: true, 
            name: true, 
            profilePhotoID: true 
          } 
        }
      }
    });

    const hasMore = pendingMembers.length > limit;
    const itemsToReturn = hasMore ? pendingMembers.slice(0, -1) : pendingMembers;
    const nextCursor = hasMore ? itemsToReturn[itemsToReturn.length - 1].id : null;

    // Generate signed URLs for profile photos
    const membersWithUrls = await Promise.all(
      itemsToReturn.map(async (member) => {
        const profilePhotoUrl = member.user.profilePhotoID
          ? await getSignedUrl(s3Client, new GetObjectCommand({
              Bucket: process.env.USER_IMAGE_BUCKET_NAME,
              Key: `${member.user.id}/${member.user.profilePhotoID}.jpg`
            }), { expiresIn: 3600 })
          : null;

        return {
          id: member.id,
          userId: member.user.id,
          userName: member.user.name,
          profilePhotoUrl,
          requestedAt: member.createdAt
        };
      })
    );

    return {
      statusCode: 200,
      headers: {
        'Cache-Control': 'private, no-store'
      },
      body: JSON.stringify({
        pendingMembers: membersWithUrls,
        hasMore,
        nextCursor
      })
    };
  } catch (error) {
    console.error('Get pending members error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error retrieving pending members',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// Approve or decline RSVP - host only
// This endpoint handles approving or declining pending RSVPs with the following requirements:
// 1. User must be authenticated
// 2. User must be the event host
// 3. Can approve (PENDING -> GOING) or decline (PENDING -> delete)
// 4. Sends notification to the user
export const handleApproveDeclineRSVP = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
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

    const hostUid = authResult.user.uid;

    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Request body is required' })
      };
    }

    const { rsvpId, action } = JSON.parse(event.body);

    if (!rsvpId || !action) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'RSVP ID and action are required' })
      };
    }

    if (!['approve', 'decline'].includes(action)) {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Action must be either "approve" or "decline"' })
      };
    }

    const prisma = await initializeDatabase();

    // Get the RSVP and verify it exists and is pending
    const rsvp = await prisma.eventRSVP.findUnique({
      where: { id: rsvpId },
      include: {
        event: { select: { hostId: true, name: true } },
        user: { select: { id: true, name: true } }
      }
    });

    if (!rsvp) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'RSVP not found' })
      };
    }

    // Verify user is the event host
    if (rsvp.event.hostId !== hostUid) {
      return {
        statusCode: 403,
        body: JSON.stringify({ message: 'Access denied. Only event hosts can approve/decline RSVPs.' })
      };
    }

    // Verify RSVP is in pending status
    if (rsvp.status !== 'PENDING') {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'RSVP is not in pending status' })
      };
    }

    let result;
    if (action === 'approve') {
      // Update status to GOING
      result = await prisma.eventRSVP.update({
        where: { id: rsvpId },
        data: { status: 'GOING' }
      });
    } else {
      // Delete the RSVP (decline)
      result = await prisma.eventRSVP.delete({
        where: { id: rsvpId }
      });
    }

    // Send notification to the user
    try {
      const message = action === 'approve' 
        ? `Your RSVP to "${rsvp.event.name}" has been approved!`
        : `Your RSVP to "${rsvp.event.name}" was declined.`;

      // Only send notifications in production mode
      if (process.env.NODE_ENV === 'production') {
        // Get user's FCM token and send notification
        const user = await prisma.user.findUnique({
          where: { id: rsvp.user.id },
          select: { fcmToken: true }
        });

        if (user?.fcmToken) {
          await admin.messaging().send({
            token: user.fcmToken,
            notification: {
              title: action === 'approve' ? 'RSVP Approved!' : 'RSVP Update',
              body: message
            },
            data: {
              type: 'rsvp_decision',
              eventId: rsvp.eventId,
              action: action
            }
          });
        }
      } else {
        console.log(`[DEBUG] Would send notification: ${message}`);
      }
    } catch (notifyErr) {
      console.error('Approval notification error:', notifyErr);
    }

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: `RSVP ${action}d successfully`,
        action,
        rsvpId
      })
    };
  } catch (error) {
    console.error('Approve/decline RSVP error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing RSVP decision',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

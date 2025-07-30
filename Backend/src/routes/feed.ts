import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { s3Client } from '../config/s3';

// Get all posts for a user's coves (posts from coves they're members of)
// This endpoint handles retrieving all posts from coves the user is a member of with the following requirements:
// 1. User must be authenticated
// 2. Posts are returned with pagination using cursor-based approach
// 3. Each post includes the user's like status and cove information
export const handleGetFeedPosts = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving feed posts.'
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
    const cursor = event.queryStringParameters?.cursor;
    const requestedLimit = parseInt(event.queryStringParameters?.limit || '10');
    const limit = Math.min(requestedLimit, 50); // Enforce maximum limit of 50

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Get posts from all coves the user is a member of
    const posts = await prisma.post.findMany({
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
        // Only get likes for the current user to return their status
        likes: {
          where: {
            userId: user.uid
          }
        },
        // Include author information (id and name)
        author: {
          select: {
            id: true,
            name: true,
            profilePhotoID: true
          }
        },
        // Include cove information (id and name)
        cove: {
          select: {
            id: true,
            name: true
          }
        }
      },
      // Order posts by creation date descending (newest first)
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
    const hasMore = posts.length > limit;
    // Remove the extra item we fetched if there are more results
    const postsToReturn = hasMore ? posts.slice(0, -1) : posts;

    // Return success response with posts and pagination info
    return {
      statusCode: 200,
      body: JSON.stringify({
        posts: await Promise.all(postsToReturn.map(async post => {
          // Get the user's like status
          const userLike = post.likes[0];
          
          // Count likes for this post
          const likeCount = await prisma.postLike.count({
            where: {
              postId: post.id
            }
          });
          
          // Generate profile photo URL if it exists
          const profilePhotoUrl = post.author.profilePhotoID ? 
            await getSignedUrl(s3Client, new GetObjectCommand({
              Bucket: process.env.USER_IMAGE_BUCKET_NAME,
              Key: `${post.author.id}/${post.author.profilePhotoID}.jpg`
            }), { expiresIn: 3600 }) : 
            null;

          return {
            id: post.id,
            content: post.content,
            coveId: post.coveId,
            coveName: post.cove.name,
            authorId: post.authorId,
            authorName: post.author.name,
            authorProfilePhotoUrl: profilePhotoUrl,
            isLiked: userLike ? true : false,
            likeCount: likeCount,
            createdAt: post.createdAt
          };
        })),
        pagination: {
          hasMore,
          nextCursor: hasMore ? posts[posts.length - 2].id : null
        }
      })
    };
  } catch (error) {
    console.error('Get feed posts route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get feed posts request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// TODO: In the future, consider handling MAYBE responses as well for a more comprehensive calendar view
// Get all events for a user's upcoming events (events from coves they're members of)
// This endpoint handles retrieving all events from coves the user is a member of with the following requirements:
// 1. User must be authenticated
// 2. Events are returned with pagination using cursor-based approach
// 3. Each event includes the user's RSVP status and cove information
export const handleGetUpcomingEvents = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving upcoming events.'
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
          // Get the user's RSVP status
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
    console.error('Get upcoming events route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get upcoming events request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
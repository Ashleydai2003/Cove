import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { s3Client } from '../config/s3';

// Flexible feed endpoint that can return events, posts, or both
// This endpoint handles retrieving feed items with the following requirements:
// 1. User must be authenticated
// 2. Items are returned with pagination using cursor-based approach
// 3. Supports filtering by type (events, posts, or both)
// 4. Each item includes user interaction status (RSVP/like)
export const handleGetFeed = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving feed items.'
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

    // Get query parameters
    const cursor = event.queryStringParameters?.cursor;
    const requestedLimit = parseInt(event.queryStringParameters?.limit || '10');
    const limit = Math.min(requestedLimit, 50); // Enforce maximum limit of 50
    
    // Parse types parameter - defaults to both events and posts
    const typesParam = event.queryStringParameters?.types || 'event,post';
    const types = typesParam.split(',').map(t => t.trim().toLowerCase());
    
    // Validate types parameter
    const validTypes = ['event', 'post'];
    const requestedTypes = types.filter(t => validTypes.includes(t));
    if (requestedTypes.length === 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Invalid types parameter. Must be one or more of: event, post'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Fetch events and posts based on requested types
    const feedItems: Array<{
      id: string;
      type: 'event' | 'post';
      createdAt: Date;
      data: any;
    }> = [];

    // Fetch events if requested
    if (requestedTypes.includes('event')) {
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
          cove: {
            select: {
              id: true,
              name: true,
              coverPhotoID: true
            }
          },
          coverPhoto: {
            select: {
              id: true
            }
          }
        },
        orderBy: {
          date: 'asc'
        }
      });

      // Add events to feed items
      for (const event of events) {
        feedItems.push({
          id: event.id,
          type: 'event',
          createdAt: event.createdAt,
          data: event
        });
      }
    }

    // Fetch posts if requested
    if (requestedTypes.includes('post')) {
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
          likes: {
            where: {
              userId: user.uid
            }
          },
          author: {
            select: {
              id: true,
              name: true,
              profilePhotoID: true
            }
          },
          cove: {
            select: {
              id: true,
              name: true
            }
          }
        },
        orderBy: {
          createdAt: 'desc'
        }
      });

      // Add posts to feed items
      for (const post of posts) {
        feedItems.push({
          id: post.id,
          type: 'post',
          createdAt: post.createdAt,
          data: post
        });
      }
    }

    // Sort all items by creation date (newest first for posts, earliest first for events)
    // For now, we'll use a simple approach: posts by createdAt desc, events by date asc
    // In the future, this could be replaced with a more sophisticated ranking algorithm
    feedItems.sort((a, b) => {
      if (a.type === 'post' && b.type === 'post') {
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
      } else if (a.type === 'event' && b.type === 'event') {
        return new Date(a.data.date).getTime() - new Date(b.data.date).getTime();
      } else {
        // For mixed types, prioritize events (they're time-sensitive)
        return a.type === 'event' ? -1 : 1;
      }
    });

    // Apply cursor-based pagination
    let itemsToReturn = feedItems;
    if (cursor) {
      // Find the item after the cursor
      const cursorIndex = feedItems.findIndex(item => item.id === cursor);
      if (cursorIndex !== -1 && cursorIndex < feedItems.length - 1) {
        itemsToReturn = feedItems.slice(cursorIndex + 1);
      } else {
        itemsToReturn = [];
      }
    }

    // Apply limit
    const hasMore = itemsToReturn.length > limit;
    const itemsToProcess = hasMore ? itemsToReturn.slice(0, limit) : itemsToReturn;

    // Process items and generate discriminated response
    const items = await Promise.all(itemsToProcess.map(async item => {
          if (item.type === 'event') {
            const event = item.data;
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
              kind: 'event',
              id: event.id,
              rank: 0.987, // TODO: Implement ranking algorithm
              event: {
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
              }
            };
          } else if (item.type === 'post') {
            const post = item.data;
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
              kind: 'post',
              id: post.id,
              rank: 0.945, // TODO: Implement ranking algorithm
              post: {
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
              }
            };
          }
        }));

    // Return success response with discriminated feed items and pagination info
    return {
      statusCode: 200,
      body: JSON.stringify({
        items: items,
        pagination: {
          hasMore,
          nextCursor: hasMore ? itemsToProcess[itemsToProcess.length - 1].id : null
        }
      })
    };
  } catch (error) {
    console.error('Get feed route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get feed request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

 
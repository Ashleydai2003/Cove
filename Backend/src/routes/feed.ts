import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { s3Client } from '../config/s3';
import { FeedService } from '../services/feedService';

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

    // Initialize database connection and feed service
    const prisma = await initializeDatabase();
    const feedService = new FeedService(prisma);

    // Get feed items using the service
    const feedResponse = await feedService.getFeedItems({
      limit,
      cursor,
      types: requestedTypes,
      userId: user.uid
    });

    // Process items to add S3 URLs and format response
    const processedItems = await Promise.all(feedResponse.items.map(async item => {
      if (item.kind === 'event') {
        const event = item.event;
        const userRsvp = event.rsvps?.[0];
        
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
          rank: item.rank,
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
      } else if (item.kind === 'post') {
        const post = item.post;
        const userLike = post.likes?.[0];
        
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
          rank: item.rank,
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

    // Return success response with processed feed items and pagination info
    return {
      statusCode: 200,
      body: JSON.stringify({
        items: processedItems,
        pagination: feedResponse.pagination
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

 
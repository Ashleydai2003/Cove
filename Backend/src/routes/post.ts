import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { s3Client } from '../config/s3';
import * as admin from 'firebase-admin';

// Create a new post
// This endpoint handles post creation with the following requirements:
// 1. User must be authenticated
// 2. User must be a member of the cove
// 3. Content and coveId are required
// 4. Content has a maximum length (enforced at API layer)
export const handleCreatePost = async (request: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only POST is allowed
    if (request.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for creating posts.'
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

    // Extract required fields from request body
    const { 
      content, 
      coveId 
    } = JSON.parse(request.body);

    // Validate all required fields are present
    if (!content || !coveId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Content and coveId are required fields'
        })
      };
    }

    // Validate content length (max 1000 characters)
    if (content.length > 1000) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Post content cannot exceed 1000 characters'
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
    if (!cove) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Cove not found'
        })
      };
    }

    // Check if user is a member of the cove
    if (cove.members.length === 0) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'You must be a member of this cove to create posts'
        })
      };
    }

    // Create the post in the database
    const newPost = await prisma.post.create({
      data: {
        content,
        coveId,
        authorId: user.uid,
      }
    });

    // Return success response with post details
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Post created successfully',
        post: {
          id: newPost.id,
          content: newPost.content,
          coveId: newPost.coveId,
          authorId: newPost.authorId,
          createdAt: newPost.createdAt
        }
      })
    };
    console.log('Create post response:', response);

    // Best-effort notify cove members (except author)
    try {
      const [members, author] = await Promise.all([
        prisma.coveMember.findMany({ where: { coveId }, select: { userId: true, user: { select: { fcmToken: true } } } }),
        prisma.user.findUnique({ where: { id: user.uid }, select: { name: true } })
      ]);
      const authorName = author?.name || 'Someone';
      for (const m of members) {
        if (m.userId === user.uid) continue;
        const token = m.user.fcmToken;
        if (!token) continue;
        try {
          if (process.env.NODE_ENV === 'production') {
            await admin.messaging().send({
              token,
              notification: {
                title: '🗣️ New post in your cove',
                body: content.length > 80 ? content.slice(0, 77) + '…' : content
              },
              data: {
                type: 'post_created',
                coveId,
                postId: newPost.id
              }
            });
          } else {
            console.log('Skipping push notification in non-production (post created)');
          }
        } catch (err) {
          console.error('Post created notify error:', err);
        }
      }
    } catch (notifyErr) {
      console.error('Post creation notify error:', notifyErr);
    }
    return response;
  } catch (error) {
    // Handle any errors that occur during post creation
    console.error('Create post route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing create post request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('Create post error response:', errorResponse);
    return errorResponse;
  }
};

// Get posts for a specific cove with pagination
// This endpoint handles retrieving posts for a specific cove with the following requirements:
// 1. User must be authenticated
// 2. User must be a member of the cove
// 3. Posts are returned with pagination using cursor-based approach
// 4. Each post includes the user's like status
export const handleGetCovePosts = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving cove posts.'
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
          message: 'You must be a member of this cove to view its posts'
        })
      };
    }

    // Get pagination parameters from query string
    const cursor = event.queryStringParameters?.cursor;
    const requestedLimit = parseInt(event.queryStringParameters?.limit || '10');
    const limit = Math.min(requestedLimit, 50); // Enforce maximum limit of 50

    // Get posts with pagination
    const posts = await prisma.post.findMany({
      where: {
        coveId: coveId
      },
      include: {
        // Filter likes to only include the current user's like
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
        // Include cove information
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
    console.error('Get cove posts route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get cove posts request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// TODO: Feed functionality has been moved to feed.ts - use handleGetFeed instead

// Get a specific post by ID
// This endpoint handles retrieving a specific post with the following requirements:
// 1. User must be authenticated
// 2. User must be a member of the post's cove
// 3. Returns all post details including author info, cove info, and user's like status
export const handleGetPost = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only GET is allowed
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for retrieving post details.'
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

    // Get postId from path parameters
    const postId = event.queryStringParameters?.postId;
    if (!postId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Post ID is required'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Get post with all related data
    const postData = await prisma.post.findUnique({
      where: { id: postId },
      include: {
        // Include author information
        author: {
          select: {
            id: true,
            name: true,
            profilePhotoID: true
          }
        },
        // Include cove information
        cove: {
          select: {
            id: true,
            name: true,
            members: {
              where: { userId: user.uid }
            }
          }
        },
        // Include all likes for the post
        likes: {
          include: {
            user: {
              select: {
                id: true,
                name: true
              }
            }
          }
        }
      }
    });

    // Check if post exists
    if (!postData) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Post not found'
        })
      };
    }

    // Check if user is a member of the cove
    if (postData.cove.members.length === 0) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'You must be a member of this cove to view its posts'
        })
      };
    }

    // Get the user's like status
    const userLike = postData.likes.find(like => like.userId === user.uid);
    
    // Return success response with post details
    return {
      statusCode: 200,
      body: JSON.stringify({
        post: {
          id: postData.id,
          content: postData.content,
          coveId: postData.coveId,
          author: {
            id: postData.author.id,
            name: postData.author.name
          },
          cove: {
            id: postData.cove.id,
            name: postData.cove.name
          },
          isLiked: userLike ? true : false,
          likes: postData.likes.map(like => ({
            id: like.id,
            userId: like.userId,
            userName: like.user.name,
            createdAt: like.createdAt
          })),
          createdAt: postData.createdAt,
          isAuthor: postData.authorId === user.uid
        }
      })
    };
  } catch (error) {
    console.error('Get post route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing get post request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

// Toggle a user's like status for a post
// This endpoint handles toggling like status with the following requirements:
// 1. User must be authenticated
// 2. User must be a member of the post's cove
// 3. If user has already liked the post, unlike it; otherwise, like it
export const handleTogglePostLike = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only POST is allowed
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for toggling post likes.'
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
    const { postId } = JSON.parse(event.body);

    // Validate required fields
    if (!postId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Post ID is required'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Check if user is a member of the post's cove
    const postData = await prisma.post.findUnique({
      where: { id: postId },
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

    // Check if post exists
    if (!postData) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Post not found'
        })
      };
    }

    // Check if user is a member of the cove
    if (postData.cove.members.length === 0) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'You must be a member of this cove to like its posts'
        })
      };
    }

    // Check if user has already liked the post
    const existingLike = await prisma.postLike.findUnique({
      where: {
        postId_userId: {
          postId: postId,
          userId: user.uid
        }
      }
    });

    let action: string;
    let likeCount: number;

    if (existingLike) {
      // User has already liked the post, so unlike it
      await prisma.postLike.delete({
        where: {
          postId_userId: {
            postId: postId,
            userId: user.uid
          }
        }
      });
      action = 'unliked';
    } else {
      // User hasn't liked the post, so like it
      await prisma.postLike.create({
        data: {
          postId: postId,
          userId: user.uid
        }
      });
      action = 'liked';
    }

    // Get updated like count
    likeCount = await prisma.postLike.count({
      where: {
        postId: postId
      }
    });

    // Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: `Post ${action} successfully`,
        action: action,
        likeCount: likeCount
      })
    };
  } catch (error) {
    console.error('Toggle post like route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing post like toggle request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
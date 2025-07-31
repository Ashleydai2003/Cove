import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import {
  ListObjectsV2Command,
  DeleteObjectsCommand,
  _Object,
  ListObjectsV2CommandOutput
} from '@aws-sdk/client-s3';
import { s3Client } from '../config/s3';

/**
 * Deletes all objects in S3 with a given prefix
 * @param bucketName The S3 bucket name
 * @param prefix The prefix to match objects for deletion
 */
async function deleteObjectsWithPrefix(bucketName: string, prefix: string) {
  let continuationToken: string | undefined = undefined;
  let totalDeleted = 0;

  do {
    const listCommand: ListObjectsV2Command = new ListObjectsV2Command({
      Bucket: bucketName,
      Prefix: prefix,
      ContinuationToken: continuationToken
    });

    const listResponse: ListObjectsV2CommandOutput = await s3Client.send(listCommand);
    const objectsToDelete: _Object[] = listResponse.Contents ?? [];

    if (objectsToDelete.length > 0) {
      const deleteCommand = new DeleteObjectsCommand({
        Bucket: bucketName,
        Delete: {
          Objects: objectsToDelete.map((obj) => ({ Key: obj.Key! }))
        }
      });

      await s3Client.send(deleteCommand);
      totalDeleted += objectsToDelete.length;
      console.log(`Deleted ${objectsToDelete.length} objects under prefix "${prefix}"`);
    }

    continuationToken = listResponse.NextContinuationToken;
  } while (continuationToken);

  console.log(`Total objects deleted: ${totalDeleted}`);
  return totalDeleted;
}

/**
 * Handles user deletion
 * 
 * This endpoint deletes a user and all their associated data:
 * - User profile and photos
 * - Friendships and friend requests
 * - Cove memberships
 * - Event RSVPs
 * - User-created events
 * - User-created coves
 * 
 * Error cases:
 * - 401: Unauthorized
 * - 405: Invalid HTTP method
 * - 500: Server error
 */
export const handleDeleteUser = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Step 1: Validate request method
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for user deletion.'
        })
      };
    }

    // Step 2: Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 3: Get the authenticated user's info
    const userId = authResult.user.uid;

    // Step 4: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 5: Check if user exists and get their photos
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        profilePhoto: true
      }
    });

    if (!user) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'User not found'
        })
      };
    }

    // Step 6: Delete user's photos from S3 if they exist
    if (user.profilePhoto) {
      const bucketName = process.env.USER_IMAGE_BUCKET_NAME;
      if (!bucketName) {
        throw new Error('USER_IMAGE_BUCKET_NAME environment variable is not set');
      }

      console.log(`Starting S3 deletion for user ${userId}`);
      const deletedCount = await deleteObjectsWithPrefix(bucketName, `${userId}/`);
      console.log(`Completed S3 deletion for user ${userId}, deleted ${deletedCount} objects`);
    }

    // Step 7: Delete S3 images for user's created coves and events
    const userCoves = await prisma.cove.findMany({
      where: { creatorId: userId },
      select: { id: true }
    });

    const userEvents = await prisma.event.findMany({
      where: { hostId: userId },
      select: { id: true }
    });

    const coveBucketName = process.env.COVE_IMAGE_BUCKET_NAME;
    if (!coveBucketName) {
      throw new Error('COVE_IMAGE_BUCKET_NAME environment variable is not set');
    }

    const eventBucketName = process.env.EVENT_IMAGE_BUCKET_NAME;
    if (!eventBucketName) {
      throw new Error('EVENT_IMAGE_BUCKET_NAME environment variable is not set');
    }

    for (const cove of userCoves) {
      console.log(`Starting S3 deletion for cove ${cove.id}`);
      const deletedCount = await deleteObjectsWithPrefix(coveBucketName, `${cove.id}/`);
      console.log(`Completed S3 deletion for cove ${cove.id}, deleted ${deletedCount} objects`);
    }

    for (const event of userEvents) {
      console.log(`Starting S3 deletion for event ${event.id}`);
      const deletedCount = await deleteObjectsWithPrefix(eventBucketName, `${event.id}/`);
      console.log(`Completed S3 deletion for event ${event.id}, deleted ${deletedCount} objects`);
    }

    // Step 8: Delete all user data in a transaction
    await prisma.$transaction(async (tx) => {
      // Delete user's profile
      await tx.userProfile.deleteMany({
        where: { userId }
      });

      // Delete user's photos
      await tx.userImage.deleteMany({
        where: { userId }
      });

      // Delete user's friendships
      await tx.friendship.deleteMany({
        where: {
          OR: [
            { user1Id: userId },
            { user2Id: userId }
          ]
        }
      });

      // Delete user's friend requests (sent and received)
      await tx.friendRequest.deleteMany({
        where: {
          OR: [
            { fromUserId: userId },
            { toUserId: userId }
          ]
        }
      });

      // Delete user's event RSVPs (where user RSVP'd to events)
      await tx.eventRSVP.deleteMany({
        where: { userId }
      });

      // Delete RSVPs to events created by the user
      await tx.eventRSVP.deleteMany({
        where: {
          eventId: {
            in: userEvents.map(event => event.id)
          }
        }
      });

      // Delete user's cove memberships
      await tx.coveMember.deleteMany({
        where: { userId }
      });

      // Delete invites sent by the user
      await tx.invite.deleteMany({
        where: { sentByUserId: userId }
      });

      // Delete event images for events created by the user
      await tx.eventImage.deleteMany({
        where: {
          eventId: {
            in: userEvents.map(event => event.id)
          }
        }
      });

      // Delete user's created events
      await tx.event.deleteMany({
        where: { hostId: userId }
      });

       // Delete cove images for coves created by the user
       await tx.coveImage.deleteMany({
        where: {
          coveId: {
            in: userCoves.map(cove => cove.id)
          }
        }
      });

      // TODO: decide if we want to delete the coves or not
     
      // Delete cove memberships for coves created by the user (to avoid FK constraint)
      if (userCoves.length > 0) {
        await tx.coveMember.deleteMany({
          where: {
            coveId: { in: userCoves.map(cove => cove.id) }
          }
        });
        // Delete all RSVPs to events in coves created by the user
        const coveEventIds = (await tx.event.findMany({
          where: { coveId: { in: userCoves.map(cove => cove.id) } },
          select: { id: true }
        })).map(event => event.id);
        if (coveEventIds.length > 0) {
          await tx.eventRSVP.deleteMany({
            where: { eventId: { in: coveEventIds } }
          });
          // Delete all event images for events in coves created by the user
          await tx.eventImage.deleteMany({
            where: { eventId: { in: coveEventIds } }
          });
        }
        // Delete all events in coves created by the user (to avoid FK constraint)
        await tx.event.deleteMany({
          where: {
            coveId: { in: userCoves.map(cove => cove.id) }
          }
        });
      }

       // Delete user's post likes
      await tx.postLike.deleteMany({
        where: { userId }
      });

      // Delete post likes for posts created by the user
      const userPosts = await tx.post.findMany({
        where: { authorId: userId },
        select: { id: true }
      });

      if (userPosts.length > 0) {
        await tx.postLike.deleteMany({
          where: {
            postId: {
              in: userPosts.map(post => post.id)
            }
          }
        });
      }

      // Delete user's created posts
      await tx.post.deleteMany({
        where: { authorId: userId }
      });

      // Delete post likes for posts in coves created by the user
      if (userCoves.length > 0) {
        const covePostIds = (await tx.post.findMany({
          where: { coveId: { in: userCoves.map(cove => cove.id) } },
          select: { id: true }
        })).map(post => post.id);
        
        if (covePostIds.length > 0) {
          await tx.postLike.deleteMany({
            where: { postId: { in: covePostIds } }
          });
        }
        
        // Delete posts in coves created by the user
        await tx.post.deleteMany({
          where: { coveId: { in: userCoves.map(cove => cove.id) } }
        });
      }

      // Delete user's created coves
       await tx.cove.deleteMany({
        where: { creatorId: userId }
      });

      // Finally, delete the user
      await tx.user.delete({
        where: { id: userId }
      });
    });

    // Step 9: Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'User and all associated data deleted successfully'
      })
    };
  } catch (error) {
    console.error('Delete user route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing user deletion',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

/**
 * Handles event deletion
 * 
 * This endpoint deletes an event and its associated data:
 * - Event RSVPs
 * - Event cover photo
 * 
 * Requirements:
 * - User must be authenticated
 * - User must be the host of the event
 * 
 * Error cases:
 * - 400: Missing eventId
 * - 401: Unauthorized
 * - 403: Not the event host
 * - 404: Event not found
 * - 405: Invalid HTTP method
 * - 500: Server error
 */
export const handleDeleteEvent = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Step 1: Validate request method
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for event deletion.'
        })
      };
    }

    // Step 2: Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 3: Get the authenticated user's info
    const userId = authResult.user.uid;

    // Step 4: Get eventId from request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { eventId } = JSON.parse(event.body);
    if (!eventId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Event ID is required'
        })
      };
    }

    // Step 5: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 6: Get event and verify user is the host
    const eventToDelete = await prisma.event.findUnique({
      where: { id: eventId },
      include: {
        coverPhoto: {
          select: {
            id: true
          }
        }
      }
    });

    if (!eventToDelete) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Event not found'
        })
      };
    }

    if (eventToDelete.hostId !== userId) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Only the event host can delete the event'
        })
      };
    }

    // Step 7: Delete event cover photo from S3 if it exists
    if (eventToDelete.coverPhoto) {
      const bucketName = process.env.EVENT_IMAGE_BUCKET_NAME;
      if (!bucketName) {
        throw new Error('EVENT_IMAGE_BUCKET_NAME environment variable is not set');
      }

      console.log(`Starting S3 deletion for event ${eventId}`);
      const deletedCount = await deleteObjectsWithPrefix(bucketName, `${eventId}/`);
      console.log(`Completed S3 deletion for event ${eventId}, deleted ${deletedCount} objects`);
    }

    // Step 8: Delete event and associated data in a transaction
    await prisma.$transaction(async (tx) => {
      // Delete event RSVPs
      await tx.eventRSVP.deleteMany({
        where: { eventId }
      });

      // Delete event cover photo record
      if (eventToDelete.coverPhoto) {
        await tx.eventImage.delete({
          where: { id: eventToDelete.coverPhoto.id }
        });
      }

      // Delete the event
      await tx.event.delete({
        where: { id: eventId }
      });
    });

    // Step 9: Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Event and associated data deleted successfully'
      })
    };
  } catch (error) {
    console.error('Delete event route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing event deletion',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
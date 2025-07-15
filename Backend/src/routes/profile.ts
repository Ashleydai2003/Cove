// Currently a placeholder route
// This will be used to retrieve profile information in the future

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { GetObjectCommand } from '@aws-sdk/client-s3';
// used to generate a temporary, secure URL for accessing the user's photos 
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { s3Client } from '../config/s3';

export const handleProfile = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is GET
    // TODO: add POST support for editing profile 
    if (event.httpMethod !== 'GET') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only GET requests are accepted for profile retrieval.'
        })
      };
    }

    // Step 1: Authenticate the request (any logged-in user can view profiles)
    const authResult = await authMiddleware(event);
    
    // Step 2: Check if auth failed (returns 401 response)
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 3: Get target user ID from query parameters 
    // If no target user ID is provided, default assume authenticated user's ID
    const targetUserId = event.queryStringParameters?.userId || authResult.user.uid;

    console.log('Getting profile for user:', targetUserId);

    // Step 4: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 5: Get user profile
    const userProfile = await prisma.user.findUnique({
      where: {
        id: targetUserId
      },
      include: {
        profile: true,
        photos: true,
        friendships1: true,
        friendships2: true,
        receivedFriendRequests: true,
        coveMemberships: true
      }
    });

    if (!userProfile) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'User profile not found'
        })
      };
    }

    // Calculate basic counts
    const friendCount = userProfile.friendships1.length + userProfile.friendships2.length;
    const requestCount = userProfile.receivedFriendRequests.length;
    const coveCount = userProfile.coveMemberships.length;

    // Additional stats when viewing someone else's profile
    let sharedCoveCount = 0;
    let sharedEventCount = 0;

    const viewerId = authResult.user.uid;
    if (viewerId && viewerId !== targetUserId) {
      // Fetch cove memberships for both users and find overlap
      const [viewerMemberships, targetMemberships] = await Promise.all([
        prisma.coveMember.findMany({ where: { userId: viewerId }, select: { coveId: true } }),
        prisma.coveMember.findMany({ where: { userId: targetUserId }, select: { coveId: true } })
      ]);

      const viewerCoveIds = new Set(viewerMemberships.map(m => m.coveId));
      sharedCoveCount = targetMemberships.filter(m => viewerCoveIds.has(m.coveId)).length;

      // Fetch GOING RSVPs for both users and find shared events
      const GOING = 'GOING';
      const [viewerRsvps, targetRsvps] = await Promise.all([
        prisma.eventRSVP.findMany({ where: { userId: viewerId, status: GOING }, select: { eventId: true } }),
        prisma.eventRSVP.findMany({ where: { userId: targetUserId, status: GOING }, select: { eventId: true } })
      ]);

      const viewerEventIds = new Set(viewerRsvps.map(r => r.eventId));
      sharedEventCount = targetRsvps.filter(r => viewerEventIds.has(r.eventId)).length;
    }

    // Calculate shared friends (mutual friends) between viewer and target
    let sharedFriendCount = 0;
    let sharedFriends: { id: string; name: string | null }[] = [];

    if (viewerId && viewerId !== targetUserId) {
      // 1. Fetch viewer friendships
      const viewerFriendships = await prisma.friendship.findMany({
        where: {
          OR: [
            { user1Id: viewerId },
            { user2Id: viewerId }
          ]
        },
        select: { user1Id: true, user2Id: true }
      });

      const viewerFriendIds = new Set<string>();
      viewerFriendships.forEach(f => {
        viewerFriendIds.add(f.user1Id === viewerId ? f.user2Id : f.user1Id);
      });

      // 2. Fetch target friendships
      const targetFriendships = await prisma.friendship.findMany({
        where: {
          OR: [
            { user1Id: targetUserId },
            { user2Id: targetUserId }
          ]
        },
        select: { user1Id: true, user2Id: true }
      });

      const mutualIds: string[] = [];
      targetFriendships.forEach(f => {
        const otherId = f.user1Id === targetUserId ? f.user2Id : f.user1Id;
        if (viewerFriendIds.has(otherId)) {
          mutualIds.push(otherId);
        }
      });

      sharedFriendCount = mutualIds.length;

      if (sharedFriendCount > 0) {
        const mutualUsers = await prisma.user.findMany({
          where: { id: { in: mutualIds } },
          select: { id: true, name: true }
        });
        sharedFriends = mutualUsers;
      }
    }

    // Step 6: Get S3 URLs for all photos
    const photoUrls = await Promise.all(
      userProfile.photos.map(async (photo) => {
        const bucketUrl = process.env.USER_IMAGE_BUCKET_URL;
        if (!bucketUrl) {
          throw new Error('USER_IMAGE_BUCKET_URL environment variable is not set');
        }

        const s3Key = `${targetUserId}/${photo.id}.jpg`;
        
        // Generate a presigned URL that expires in 1 hour
        const command = new GetObjectCommand({
          Bucket: process.env.USER_IMAGE_BUCKET_NAME,
          Key: s3Key
        });
        
        return {
          id: photo.id,
          url: await getSignedUrl(s3Client, command, { expiresIn: 3600 }),
          isProfilePic: photo.id === userProfile.profilePhotoID
        };
      })
    );

    // Step 7: Return user profile with photo URLs
    // TODO: use user's privacy preferences to determine which fields to expose
    const isOwnProfile = viewerId === targetUserId;

    let profileData: any;
    if (isOwnProfile) {
      // Viewer is the profile owner – return full details
      profileData = {
        name: userProfile.name,
        phone: userProfile.phone,
        onboarding: userProfile.onboarding,
        verified: userProfile.verified,
        ...userProfile.profile, // Include all profile fields
        photos: photoUrls,
        stats: {
          friendCount,
          requestCount,
          coveCount,
          sharedCoveCount,
          sharedEventCount,
          sharedFriendCount,
          sharedFriends
        }
      };
    } else {
      // Viewer is NOT the profile owner – return a limited view
      // TODO: extend this logic to honour the target user's privacy preferences (e.g., private/public fields)
      const profilePic = photoUrls.find(p => p.isProfilePic) ?? null;

      profileData = {
        name: userProfile.name,
        userId: targetUserId,
        id: targetUserId,
        bio: userProfile.profile?.bio,
        interests: userProfile.profile?.interests ?? [],
        latitude: userProfile.profile?.latitude,
        longitude: userProfile.profile?.longitude,
        photos: profilePic ? [profilePic] : [],
        stats: {
          friendCount: 0,
          requestCount: 0,
          coveCount: 0,
          sharedCoveCount,
          sharedEventCount,
          sharedFriendCount
        }
      };
    }

    const response = {
      statusCode: 200,
      body: JSON.stringify({
        profile: profileData
      })
    };
    console.log('Profile response:', response);
    return response;
  } catch (error) {
    console.error('Profile route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing profile request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('Profile error response:', errorResponse);
    return errorResponse;
  }
};

/**
 * Handles editing a user's profile
 * 
 * This endpoint allows users to update their profile information:
 * - Basic info (name)
 * - Profile details (bio, interests, etc.)
 * - Cannot update phone number or other sensitive fields
 * 
 * Request body fields (all optional):
 * - name: string - User's display name
 * - bio: string - User's biography
 * - interests: string[] - Array of user's interests
 * - birthdate: string - User's birthdate (ISO date string)
 * - latitude: number - User's location latitude
 * - longitude: number - User's location longitude
 * - almaMater: string - User's alma mater
 * - job: string - User's job title
 * - workLocation: string - User's work location
 * - relationStatus: string - User's relationship status
 * - sexuality: string - User's sexuality
 * - gender: string - User's gender
 * 
 * Error cases:
 * - 400: Invalid request body
 * - 401: Unauthorized
 * - 404: User profile not found
 * - 405: Invalid HTTP method
 * - 500: Server error
 */
export const handleEditProfile = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Step 1: Validate request method
    // Only POST requests are allowed for profile editing
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for profile editing.'
        })
      };
    }

    // Step 2: Authenticate the request
    // This ensures only the profile owner can edit their profile
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 3: Get the authenticated user's info
    // We use the Firebase UID as the user ID
    const userId = authResult.user.uid;

    // Step 4: Parse and validate request body
    // The request body is required and must be valid JSON
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    // Step 5: Extract all possible profile fields from request body
    // All fields are optional - only provided fields will be updated
    const {
      name,
      bio,
      interests,
      birthdate,
      latitude,
      longitude,
      almaMater,
      job,
      workLocation,
      relationStatus,
      sexuality,
      gender
    } = JSON.parse(event.body);

    // Step 6: Check if any fields were provided
    // If no fields were provided, return early
    const hasUpdates = Object.values({
      name,
      bio,
      interests,
      birthdate,
      latitude,
      longitude,
      almaMater,
      job,
      workLocation,
      relationStatus,
      sexuality,
      gender
    }).some(value => value !== undefined);

    if (!hasUpdates) {
      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'No updates provided'
        })
      };
    }

    // Step 7: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 8: Check if user has a profile
    // We require a profile to exist before allowing edits
    const existingProfile = await prisma.userProfile.findUnique({
      where: { userId }
    });

    if (!existingProfile) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'User profile not found. Please create a profile first.'
        })
      };
    }

    // Step 9: Update user's name if provided
    // Name is stored in the User model, not UserProfile
    if (name !== undefined) {
      await prisma.user.update({
        where: { id: userId },
        data: { name }
      });
    }

    // Step 10: Update user profile
    // Only update fields that were provided in the request
    // birthdate is converted to a Date object if provided
    await prisma.userProfile.update({
      where: { userId },
      data: {
        bio,
        interests,
        birthdate: birthdate ? new Date(birthdate) : undefined,
        latitude,
        longitude,
        almaMater,
        job,
        workLocation,
        relationStatus,
        sexuality,
        gender
      }
    });

    // Step 11: Return success response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Profile updated successfully'
      })
    };
  } catch (error) {
    // Handle any errors that occur during profile update
    console.error('Edit profile route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing profile update',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
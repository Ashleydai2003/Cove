// Currently a placeholder route
// This will be used to retrieve profile information in the future

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3';
// used to generate a temporary, secure URL for accessing the user's photos 
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const s3Client = new S3Client({ region: process.env.AWS_REGION });

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

    // Step 5: Get user profile with all photos
    const userProfile = await prisma.user.findUnique({
      where: {
        id: targetUserId
      },
      include: {
        photos: true
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

    // Step 6: Get S3 URLs for all photos
    const photoUrls = await Promise.all(
      userProfile.photos.map(async (photo) => {
        const bucketName = process.env.USER_IMAGE_BUCKET_NAME;
        if (!bucketName) {
          throw new Error('USER_IMAGE_BUCKET_NAME environment variable is not set');
        }

        const s3Key = `${targetUserId}/${photo.id}.jpg`;
        
        // Generate a presigned URL that expires in 1 hour
        const command = new GetObjectCommand({
          Bucket: bucketName,
          Key: s3Key
        });
        
        return {
          id: photo.id,
          url: await getSignedUrl(s3Client, command, { expiresIn: 3600 }),
          isProfilePic: photo.isProfilePic
        };
      })
    );

    // Step 7: Return user profile with photo URLs
    // TODO: if user is private and the authenticated user is not the target user, 
    // only return name, bio, and profile picture + maybe other information 
    return {
      statusCode: 200,
      body: JSON.stringify({
        profile: {
          name: userProfile.name,
          phone: userProfile.phone,
          age: userProfile.age,
          birthday: userProfile.birthday,
          interests: userProfile.interests,
          latitude: userProfile.latitude,
          longitude: userProfile.longitude,
          almaMater: userProfile.almaMater,
          job: userProfile.job,
          workLocation: userProfile.workLocation,
          relationStatus: userProfile.relationStatus,
          sexuality: userProfile.sexuality,
          onboarding: userProfile.onboarding,
          photos: photoUrls
        }
      })
    };
  } catch (error) {
    console.error('Profile route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing profile request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
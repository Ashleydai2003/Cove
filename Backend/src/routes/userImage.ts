import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { S3Client, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';

const s3Client = new S3Client({ region: process.env.AWS_REGION });

export const handleUserImage = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    // TODO: later allow GET request with different process
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for image uploads.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    
    // Step 2: Check if auth failed (returns 401 response)
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 3: Get the authenticated user's info
    const user = authResult.user;
    console.log('Authenticated user:', user.uid);

    // Step 4: Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { data: base64Image, isProfilePic } = JSON.parse(event.body);

    if (!base64Image) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Image data is required'
        })
      };
    }

    // Step 5: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 6: Create UserImage record first to get the auto-generated ID
    const userImage = await prisma.userImage.create({
      data: {
        userId: user.uid
      }
    });

    // Step 7: Upload image to S3 using the auto-generated ID
    const bucketName = process.env.USER_IMAGE_BUCKET_NAME;
    if (!bucketName) {
      throw new Error('USER_IMAGE_BUCKET_NAME environment variable is not set');
    }

    const s3Key = `${user.uid}/${userImage.id}.jpg`;

    // Convert base64 to buffer
    const imageBuffer = Buffer.from(base64Image, 'base64');

    // Upload to S3
    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: s3Key,
      Body: imageBuffer,
      ContentType: 'image/jpeg'
    });
    await s3Client.send(command);

    // Step 8: If this is a profile picture, update the user's profilePhotoID
    if (isProfilePic) {
      await prisma.user.update({
        where: {
          id: user.uid
        },
        data: {
          profilePhotoID: userImage.id
        }
      });
    }

    console.log('Image upload complete for user:', user.uid);

    // Step 9: Return success message
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Image uploaded successfully'
      })
    };
    console.log('UserImage response:', response);
    return response;
  } catch (error) {
    console.error('Image upload route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing image upload request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('UserImage error response:', errorResponse);
    return errorResponse;
  }
};

/**
 * Handles updating an existing user image by replacing it with a new one.
 * This endpoint takes a specific photo ID and replaces that photo.
 * 
 * Request body:
 * - data: base64-encoded image data
 * - photoId: the ID of the photo to replace
 */
export const handleUserImageUpdate = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for image updates.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    
    // Step 2: Check if auth failed (returns 401 response)
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Step 3: Get the authenticated user's info
    const user = authResult.user;
    console.log('Authenticated user:', user.uid);

    // Step 4: Parse request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { data: base64Image, photoId } = JSON.parse(event.body);

    if (!base64Image) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Image data is required'
        })
      };
    }

    if (!photoId) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Photo ID is required'
        })
      };
    }

    // Step 5: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 6: Find the existing photo and verify ownership
    const existingPhoto = await prisma.userImage.findFirst({
      where: {
        id: photoId,
        userId: user.uid
      }
    });

    if (!existingPhoto) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Photo not found or you do not have permission to update it'
        })
      };
    }

    // Step 7: Delete old image from S3
    const bucketName = process.env.USER_IMAGE_BUCKET_NAME;
    if (!bucketName) {
      throw new Error('USER_IMAGE_BUCKET_NAME environment variable is not set');
    }

    const s3Key = `${user.uid}/${photoId}.jpg`;
    const deleteCommand = new DeleteObjectCommand({
      Bucket: bucketName,
      Key: s3Key
    });
    
    try {
      await s3Client.send(deleteCommand);
      console.log('Old image deleted from S3:', s3Key);
    } catch (error) {
      console.log('Old image not found in S3, continuing with upload:', s3Key);
    }

    // Step 8: Upload new image to S3
    const imageBuffer = Buffer.from(base64Image, 'base64');
    const command = new PutObjectCommand({
      Bucket: bucketName,
      Key: s3Key,
      Body: imageBuffer,
      ContentType: 'image/jpeg'
    });
    await s3Client.send(command);

    console.log('Image update complete for user:', user.uid, 'photoId:', photoId);

    // Step 9: Return success message
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Image updated successfully'
      })
    };
    console.log('UserImageUpdate response:', response);
    return response;
  } catch (error) {
    console.error('Image update route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing image update request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('UserImageUpdate error response:', errorResponse);
    return errorResponse;
  }
}; 
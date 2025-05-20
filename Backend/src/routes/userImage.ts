import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

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

    // Step 6: Upload image to S3
    const bucketName = process.env.USER_IMAGE_BUCKET_NAME;
    if (!bucketName) {
      throw new Error('USER_IMAGE_BUCKET_NAME environment variable is not set');
    }

    // Generate a unique key for the image
    const imageId = crypto.randomUUID();
    
    // Step 7: Create UserImage record
    const userImage = await prisma.userImage.create({
      data: {
        id: imageId,
        userId: user.uid
      }
    });

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
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Image uploaded successfully'
      })
    };
  } catch (error) {
    console.error('Image upload route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing image upload request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
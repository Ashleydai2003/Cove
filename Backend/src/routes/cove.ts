import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

// Initialize S3 client for image uploads
const s3Client = new S3Client({ region: process.env.AWS_REGION });

// Create a new cove
// This endpoint handles cove creation with the following requirements:
// 1. User must be authenticated
// 2. User must be verified
// 3. Name and location are required
// 4. Optional cover photo will be uploaded to S3
export const handleCreateCove = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only POST is allowed
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for creating coves.'
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

    // Check if user is verified - only verified users can create coves
    const prisma = await initializeDatabase();
    const userRecord = await prisma.user.findUnique({
      where: { id: user.uid }
    });

    if (!userRecord?.verified) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Only verified users can create coves'
        })
      };
    }

    // Parse and validate request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    // Extract required and optional fields from request body
    const { name, description, location, coverPhoto } = JSON.parse(event.body);

    // Validate required fields
    if (!name || !location) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Cove name and location are required fields'
        })
      };
    }

    // Create the cove in the database
    const cove = await prisma.cove.create({
      data: {
        name,
        description: description || null,
        location,
        creatorId: user.uid,
      }
    });

    // Handle cover photo upload if provided
    if (coverPhoto) {
      // Create a record for the cover photo in the database
      const coveImage = await prisma.coveImage.create({
        data: {
          coveId: cove.id
        }
      });

      // Get S3 bucket name from environment variables
      const bucketName = process.env.COVE_IMAGE_BUCKET_NAME;
      if (!bucketName) {
        throw new Error('COVE_IMAGE_BUCKET_NAME environment variable is not set');
      }

      // Prepare image for S3 upload
      const s3Key = `${cove.id}/${coveImage.id}.jpg`;
      const imageBuffer = Buffer.from(coverPhoto, 'base64');

      // Upload image to S3
      const command = new PutObjectCommand({
        Bucket: bucketName,
        Key: s3Key,
        Body: imageBuffer,
        ContentType: 'image/jpeg'
      });
      await s3Client.send(command);

      // Update cove with the cover photo reference
      await prisma.cove.update({
        where: { id: cove.id },
        data: { coverPhotoID: coveImage.id }
      });
    }

    // Automatically add the creator as an admin member of the cove
    await prisma.coveMember.create({
      data: {
        coveId: cove.id,
        userId: user.uid,
        role: 'ADMIN'
      }
    });

    // Return success response with cove details
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Cove created successfully',
        cove: {
          id: cove.id,
          name: cove.name,
          description: cove.description,
          location: cove.location,
          createdAt: cove.createdAt
        }
      })
    };
    console.log('Create cove response:', response);
    return response;
  } catch (error) {
    // Handle any errors that occur during cove creation
    console.error('Create cove route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing create cove request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('Create cove error response:', errorResponse);
    return errorResponse;
  }
};
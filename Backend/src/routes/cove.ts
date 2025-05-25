import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

const s3Client = new S3Client({ region: process.env.AWS_REGION });

// Create a new cove
export const handleCreateCove = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for creating coves.'
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

    const { name, description, location, coverPhoto } = JSON.parse(event.body);

    if (!name) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Cove name is required'
        })
      };
    }

    // Step 5: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 6: Create the cove
    const cove = await prisma.cove.create({
      data: {
        name,
        description: description || null,
        location: location || null,
        creatorId: user.uid,
      }
    });

    // Step 7: If a cover photo was provided, handle it
    if (coverPhoto) {
      // Create CoveImage record
      const coveImage = await prisma.coveImage.create({
        data: {
          coveId: cove.id
        }
      });

      // Upload to S3
      const bucketName = process.env.COVE_IMAGE_BUCKET_NAME;
      if (!bucketName) {
        throw new Error('COVE_IMAGE_BUCKET_NAME environment variable is not set');
      }

      const s3Key = `${cove.id}/${coveImage.id}.jpg`;
      const imageBuffer = Buffer.from(coverPhoto, 'base64');

     // Upload Cove Image to s3
      const command = new PutObjectCommand({
        Bucket: bucketName,
        Key: s3Key,
        Body: imageBuffer,
        ContentType: 'image/jpeg'
      });
      await s3Client.send(command);

      // Update cove with cover photo ID
      await prisma.cove.update({
        where: { id: cove.id },
        data: { coverPhotoID: coveImage.id }
      });
    }

    // Step 8: Add creator as admin member
    await prisma.coveMember.create({
      data: {
        coveId: cove.id,
        userId: user.uid,
        role: 'ADMIN'
      }
    });

    // Step 9: Return success response
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
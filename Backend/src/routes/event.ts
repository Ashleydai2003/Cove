import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

const s3Client = new S3Client({ region: process.env.AWS_REGION });

// Create a new event
export const handleCreateEvent = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for creating events.'
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

    const { 
      name, 
      description, 
      date, 
      location,
      coverPhoto,
      coveId 
    } = JSON.parse(event.body);

    // Validate required fields
    if (!name || !date || !coveId || !location) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Name, date, location, and coveId are required fields'
        })
      };
    }

    // Step 5: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 6: Check if user is an admin of the cove
    const coveMember = await prisma.coveMember.findUnique({
      where: {
        coveId_userId: {
          coveId: coveId,
          userId: user.uid
        }
      }
    });

    if (!coveMember || coveMember.role !== 'ADMIN') {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Only cove admins can create events'
        })
      };
    }

    // Step 7: Create the event
    const event = await prisma.event.create({
      data: {
        name,
        description: description || null,
        date: new Date(date),
        location,
        coveId,
        creatorId: user.uid,
      }
    });

    // Step 8: If a cover photo was provided, handle it
    if (coverPhoto) {
      // Create EventImage record
      const eventImage = await prisma.eventImage.create({
        data: {
          eventId: event.id
        }
      });

      // Upload to S3
      const bucketName = process.env.EVENT_IMAGE_BUCKET_NAME;
      if (!bucketName) {
        throw new Error('EVENT_IMAGE_BUCKET_NAME environment variable is not set');
      }

      const s3Key = `${event.id}/${eventImage.id}.jpg`;
      const imageBuffer = Buffer.from(coverPhoto, 'base64');

      const command = new PutObjectCommand({
        Bucket: bucketName,
        Key: s3Key,
        Body: imageBuffer,
        ContentType: 'image/jpeg'
      });
      await s3Client.send(command);

      // Update event with cover photo ID
      await prisma.event.update({
        where: { id: event.id },
        data: { coverPhotoID: eventImage.id }
      });
    }

    // Step 9: Return success response
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Event created successfully',
        event: {
          id: event.id,
          name: event.name,
          description: event.description,
          date: event.date,
          location: event.location,
          coveId: event.coveId,
          createdAt: event.createdAt
        }
      })
    };
    console.log('Create event response:', response);
    return response;
  } catch (error) {
    console.error('Create event route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing create event request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('Create event error response:', errorResponse);
    return errorResponse;
  }
};

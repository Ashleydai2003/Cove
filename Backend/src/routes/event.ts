import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

// Initialize S3 client for image uploads
const s3Client = new S3Client({ region: process.env.AWS_REGION });

// Create a new event
// This endpoint handles event creation with the following requirements:
// 1. User must be authenticated
// 2. User must be either the cove creator or an admin
// 3. Name, date, location, and coveId are required
// 4. Optional cover photo will be uploaded to S3
export const handleCreateEvent = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Validate request method - only POST is allowed
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for creating events.'
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

    // Extract required and optional fields from request body
    const { 
      name, 
      description, 
      date, 
      location,
      coverPhoto,
      coveId 
    } = JSON.parse(event.body);

    // Validate all required fields are present
    if (!name || !date || !coveId || !location) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Name, date, location, and coveId are required fields'
        })
      };
    }

    // Initialize database connection
    const prisma = await initializeDatabase();

    // Check if user is an admin of the cove or the cove creator
    const cove = await prisma.cove.findUnique({
      where: { id: coveId },
      include: {
        members: {
          where: { userId: user.uid }
        }
      }
    });

    // Check if the cove exists in the database
    // This prevents creating events for non-existent coves and provides a clear 404 error
    // Example: if someone tries to create an event with coveId: "non-existent-id"
    if (!cove) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'Cove not found'
        })
      };
    }

    // Check user's permission level in the cove
    const isCreator = cove.creatorId === user.uid;
    const isAdmin = cove.members[0]?.role === 'ADMIN';

    // Only cove creators and admins can create events
    if (!isCreator && !isAdmin) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'Only cove creators and admins can create events'
        })
      };
    }

    // Create the event in the database
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

    // Handle cover photo upload if provided
    if (coverPhoto) {
      // Create a record for the cover photo in the database
      const eventImage = await prisma.eventImage.create({
        data: {
          eventId: event.id
        }
      });

      // Get S3 bucket name from environment variables
      const bucketName = process.env.EVENT_IMAGE_BUCKET_NAME;
      if (!bucketName) {
        throw new Error('EVENT_IMAGE_BUCKET_NAME environment variable is not set');
      }

      // Prepare image for S3 upload
      const s3Key = `${event.id}/${eventImage.id}.jpg`;
      const imageBuffer = Buffer.from(coverPhoto, 'base64');

      // Upload image to S3
      const command = new PutObjectCommand({
        Bucket: bucketName,
        Key: s3Key,
        Body: imageBuffer,
        ContentType: 'image/jpeg'
      });
      await s3Client.send(command);

      // Update event with the cover photo reference
      await prisma.event.update({
        where: { id: event.id },
        data: { coverPhotoID: eventImage.id }
      });
    }

    // Return success response with event details
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
    // Handle any errors that occur during event creation
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

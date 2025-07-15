import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { s3Client } from '../config/s3';

/**
 * Handles GET requests to find users by their phone numbers
 * Returns basic profile info (name, photo) for matching users
 * Excludes the requesting user from results
 * 
 * Query Parameters:
 * - phoneNumbers: Comma-separated list of phone numbers to look up
 * 
 * Returns:
 * - 200: List of matching users with their profile info
 * - 400: Missing phone numbers
 * - 401: Unauthorized
 * - 405: Method not allowed
 * - 500: Server error
 */
export const handleContacts = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted.'
        })
      };
    }

    // Step 1: Authenticate the request
    const authResult = await authMiddleware(event);
    if ('statusCode' in authResult) {
      return authResult;
    }

    // Get the authenticated user's ID
    const requestingUserId = authResult.user.uid;

    // Step 2: Parse phone numbers from request body
    if (!event.body) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Request body is required'
        })
      };
    }

    const { phoneNumbers } = JSON.parse(event.body);
    if (!Array.isArray(phoneNumbers) || phoneNumbers.length === 0) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'Phone numbers array is required in request body'
        })
      };
    }

    // Step 3: Initialize database connection
    const prisma = await initializeDatabase();

    // Find all users with matching phone numbers, excluding the requesting user
    // Include their profile photo information
    const users = await prisma.user.findMany({
      where: {
        phone: {
          in: phoneNumbers
        },
        id: {
          not: requestingUserId // Exclude the requesting user
        }
      },
      include: {
        profilePhoto: true
      }
    });

    // For each matching user, generate a presigned URL for their profile photo
    const contacts = await Promise.all(
      users.map(async (user) => {
        let profilePhotoUrl = null;
        
        // If user has a profile photo, generate a presigned URL
        if (user.profilePhoto) {
          const bucketName = process.env.USER_IMAGE_BUCKET_NAME;
          if (!bucketName) {
            throw new Error('USER_IMAGE_BUCKET_NAME environment variable is not set');
          }

          // Construct S3 key using user ID and photo ID
          const s3Key = `${user.id}/${user.profilePhoto.id}.jpg`;
          
          // Generate a presigned URL that expires in 1 hour
          const command = new GetObjectCommand({
            Bucket: bucketName,
            Key: s3Key
          });
          
          profilePhotoUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 });
        }

        // Return basic profile info for each user
        return {
          id: user.id,
          name: user.name,
          phone: user.phone,
          profilePhotoUrl
        };
      })
    );

    // Return success response with contacts and pagination info
    const hasMore = false; // Assuming no more results
    const contactsToReturn = contacts.slice(0, 10); // Assuming a limit of 10 contacts
    return {
      statusCode: 200,
      body: JSON.stringify({
        contacts: contactsToReturn.map(contact => {
          // Get S3 bucket URL from environment variables
          const bucketUrl = process.env.USER_IMAGE_BUCKET_URL;
          if (!bucketUrl) {
            throw new Error('USER_IMAGE_BUCKET_URL environment variable is not set');
          }
          
          // Get the contact's profile photo URL
          const profilePhotoUrl = contact.profilePhotoUrl ? 
            `${bucketUrl}/${contact.id}/${contact.profilePhotoUrl}.jpg` : 
            null;
          
          return {
            id: contact.id,
            name: contact.name,
            profilePhotoUrl
          };
        }),
        pagination: {
          hasMore,
          nextCursor: hasMore ? contacts[contacts.length - 2].id : null
        }
      })
    };
  } catch (error) {
    console.error('Contacts route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing contacts request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('Contacts error response:', errorResponse);
    return errorResponse;
  }
}; 
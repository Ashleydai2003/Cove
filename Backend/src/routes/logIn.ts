// Login endpoint

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

const s3Client = new S3Client({ region: process.env.AWS_REGION });

export const handleLogin = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for login.'
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

    // Step 4: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 5: Check if user exists in database
    let dbUser = await prisma.user.findUnique({
      where: {
        id: user.uid // Using Firebase UID as the database ID
      }
    });

    let isNewUser = false;

    // Step 6: Create user if they don't exist
    if (!dbUser) {
      console.log('Creating new user in database');
      isNewUser = true;
      dbUser = await prisma.user.create({
        data: {
          id: user.uid, // Using Firebase UID as the database ID
          phone: user.phone_number || '' // Provide empty string as fallback
        }
      });

      // Create user's S3 prefix
      try {
        const bucketName = process.env.USER_IMAGE_BUCKET_NAME;
        const command = new PutObjectCommand({
          Bucket: bucketName,
          Key: `${user.uid}/`, // Create a folder-like prefix
          Body: '' // Empty body since we just want to create the prefix
        });
        await s3Client.send(command);
        console.log(`Created S3 prefix for user ${user.uid}`);
      } catch (s3Error) {
        console.error('Error creating S3 prefix:', s3Error);
        // Don't fail the login if S3 prefix creation fails
      }
    }

    // Step 7: Return user info with onboarding status
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: isNewUser ? 'New user created' : 'Existing user found',
        user: {
          uid: user.uid,
          isNewUser,
          // If new user, frontend should start onboarding
          // If existing user, frontend should show normal app
        }
      })
    };
  } catch (error) {
    console.error('User route error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing user request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
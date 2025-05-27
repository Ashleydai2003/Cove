// Login endpoint

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getAuth } from 'firebase-admin/auth';

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

    // Step 3.5: Get verified phone number from Firebase
    const firebaseUser = await getAuth().getUser(user.uid);
    const verifiedPhoneNumber = firebaseUser.phoneNumber;
    
    if (!verifiedPhoneNumber) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          message: 'No verified phone number found for this user'
        })
      };
    }

    // Step 4: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 4.5: Check if phone number is in admin allowlist
    const adminAllowlist = await prisma.adminPhoneAllowlist.findUnique({
      where: {
        phoneNumber: verifiedPhoneNumber
      }
    });

    // Step 5: Check if user exists in database
    let dbUser = await prisma.user.findUnique({
      where: {
        id: user.uid // Using Firebase UID as the database ID
      }
    });

    // Step 6: Create user if they don't exist
    if (!dbUser) {
      console.log('Creating new user in database');
      dbUser = await prisma.user.create({
        data: {
          id: user.uid,
          phone: verifiedPhoneNumber,
          onboarding: true,
          verified: adminAllowlist ? true : false // Set verified status based on allowlist
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

    // Step 7: Return user info
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: 'User authenticated successfully',
        user: {
          uid: dbUser.id,
          onboarding: dbUser.onboarding,
          verified: dbUser.verified,
          cove: adminAllowlist?.cove ?? null
        }
      })
    };
    console.log('Login response:', response);
    return response;
  } catch (error) {
    console.error('User route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing user request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('Login error response:', errorResponse);
    return errorResponse;
  }
}; 
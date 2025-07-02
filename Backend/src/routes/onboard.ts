import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { authMiddleware } from '../middleware/auth';
import { initializeDatabase } from '../config/database';


// TODO: there should be a default user profile photo that is used if the user does not have a profile photo
export const handleOnboard = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Check if the request method is POST
    if (event.httpMethod !== 'POST') {
      return {
        statusCode: 405,
        body: JSON.stringify({
          message: 'Method not allowed. Only POST requests are accepted for onboarding.'
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
    // make sure authenticated user is the one that is onboarding
    const user = authResult.user;
    console.log('Authenticated user:', user.uid);

    // Step 4: Initialize database connection
    const prisma = await initializeDatabase();

    // Step 5: Check if user is in onboarding state
    const existingUser = await prisma.user.findUnique({
      where: {
        id: user.uid
      },
      select: {
        onboarding: true
      }
    });

    if (!existingUser) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'User not found'
        })
      };
    }

    if (!existingUser.onboarding) {
      return {
        statusCode: 403,
        body: JSON.stringify({
          message: 'User has already completed onboarding'
        })
      };
    }

    // Step 6: Parse request body
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
      birthdate,
      hobbies,
      bio,
      latitude,
      longitude,
      almaMater,
      job,
      workLocation,
      relationStatus,
      sexuality,
      gender
    } = JSON.parse(event.body);

    // Validate numeric fields
    if (latitude && typeof latitude !== 'number') {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Latitude must be a number' })
      };
    }

    if (longitude && typeof longitude !== 'number') {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'Longitude must be a number' })
      };
    }

    console.log('Received onboarding data:', {
      name,
      birthdate,
      hobbies,
      bio,
      latitude,
      longitude,
      almaMater,
      job,
      workLocation,
      relationStatus,
      sexuality,
      gender
    });

    // Step 7: Check if user is an admin based on phone number
    const currentUser = await prisma.user.findUnique({
      where: {
        id: user.uid
      },
      select: {
        phone: true
      }
    });

    if (!currentUser) {
      return {
        statusCode: 404,
        body: JSON.stringify({
          message: 'User not found'
        })
      };
    }

    // Check if user's phone number is in admin allowlist
    const adminEntry = await prisma.adminPhoneAllowlist.findUnique({
      where: {
        phoneNumber: currentUser.phone
      }
    });

    const isAdmin = !!adminEntry;

    // Step 8: Update user information
    await prisma.user.update({
      where: {
        id: user.uid
      },
      data: {
        name: name || null,
        onboarding: false, // Mark onboarding as complete
        verified: isAdmin, // Set verified to true if user is an admin
        profile: {
          create: {
            birthdate: birthdate ? new Date(birthdate) : null,
            interests: hobbies || [],
            latitude: latitude || null,
            longitude: longitude || null,
            almaMater: almaMater || null,
            job: job || null,
            workLocation: workLocation || null,
            relationStatus: relationStatus || null,
            sexuality: sexuality || null,
            gender: gender || null,
            bio: bio || null
          }
        }
      }
    });

    // Step 9: If user is an admin, update the admin allowlist to mark them as active
    if (isAdmin && adminEntry) {
      await prisma.adminPhoneAllowlist.update({
        where: {
          phoneNumber: currentUser.phone
        },
        data: {
          isActive: true
        }
      });
      console.log('Admin user activated in allowlist:', currentUser.phone);
    }

    console.log('Onboarding complete for user:', user.uid);

    // Step 10: Return success message
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: 'User onboarding completed successfully'
      })
    };
    console.log('Onboarding response:', response);
    return response;
  } catch (error) {
    console.error('Onboarding route error:', error);
    const errorResponse = {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing onboarding request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
    console.log('Onboarding error response:', errorResponse);
    return errorResponse;
  }
};

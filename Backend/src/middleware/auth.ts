import { APIGatewayProxyEvent } from 'aws-lambda';
import * as admin from 'firebase-admin';
import { initializeFirebase } from './firebase.ts'; // Import the init function

// Auth API request like this:
// First, authenticate the request
// const authResult = await authMiddleware(event);

/**
 * Verifies a Firebase ID token from the request headers
 * 
 * This function extracts the Firebase ID token from the Authorization header,
 * verifies its authenticity using Firebase Admin SDK, and returns the decoded token.
 * 
 * @param {APIGatewayProxyEvent} event - The AWS Lambda API Gateway event
 * @returns {Promise<admin.auth.DecodedIdToken>} The decoded Firebase ID token
 * @throws {Error} If no authorization header is present or token verification fails
 */
export const verifyFirebaseToken = async (event: APIGatewayProxyEvent) => {
  await initializeFirebase(); // Always make sure Firebase is initialized before using
  try {
    // Get the Authorization header, checking both cases
    const authHeader = event.headers.Authorization || event.headers.authorization;
    
    if (!authHeader) {
      throw new Error('No authorization header');
    }

    // Extract the token from the Bearer scheme
    const token = authHeader.split('Bearer ')[1];
    
    if (!token) {
      throw new Error('No token provided');
    }

    // Verify the token using Firebase Admin SDK
    // This checks if the token is valid, not expired, and properly signed
    const decodedToken = await admin.auth().verifyIdToken(token);
    return decodedToken;
  } catch (error) {
    console.error('Error verifying token:', error);
    throw error;
  }
};

/**
 * Authentication middleware for API Gateway requests
 * 
 * This middleware verifies the Firebase ID token in the request and:
 * - If valid: Adds the decoded user information to the event object
 * - If invalid: Returns a 401 Unauthorized response
 * 
 * @param {APIGatewayProxyEvent} event - The AWS Lambda API Gateway event
 * @returns {Promise<Object>} The modified event with user info or an error response
 */
export const authMiddleware = async (event: APIGatewayProxyEvent) => {
  try {
    // Verify the token and get user information
    const decodedToken = await verifyFirebaseToken(event);
    
    // Add the decoded user information to the event object
    // This allows API handlers to access user data without re-verifying
    return {
      ...event,
      user: decodedToken,
    };
  } catch (error) {
    // Return a 401 Unauthorized response if token verification fails
    return {
      statusCode: 401,
      body: JSON.stringify({
        message: 'Unauthorized',
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
    };
  }
}; 
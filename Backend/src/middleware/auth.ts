import { APIGatewayProxyEvent } from 'aws-lambda';
import * as admin from 'firebase-admin';

/**
 * Authentication Middleware Module
 * 
 * This module provides Firebase authentication functionality for AWS Lambda functions.
 * It includes utilities to verify Firebase tokens and protect API endpoints.
 * 
 * @module auth
 * @requires aws-lambda
 * @requires firebase-admin 
 */

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}

export const verifyFirebaseToken = async (event: APIGatewayProxyEvent) => {
  try {
    const authHeader = event.headers.Authorization || event.headers.authorization;
    
    if (!authHeader) {
      throw new Error('No authorization header');
    }

    const token = authHeader.split('Bearer ')[1];
    
    if (!token) {
      throw new Error('No token provided');
    }

    const decodedToken = await admin.auth().verifyIdToken(token);
    return decodedToken;
  } catch (error) {
    console.error('Error verifying token:', error);
    throw error;
  }
};

export const authMiddleware = async (event: APIGatewayProxyEvent) => {
  try {
    const decodedToken = await verifyFirebaseToken(event);
    return {
      ...event,
      user: decodedToken,
    };
  } catch (error) {
    return {
      statusCode: 401,
      body: JSON.stringify({
        message: 'Unauthorized',
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
    };
  }
}; 
// /Backend/src/index.ts

// This file is supposed to be the entry point for the backend application.
// Currently, it is just a placeholder hello world function

import { APIGatewayProxyEvent, APIGatewayProxyResult, Context } from 'aws-lambda';
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
import { authMiddleware } from './middleware/auth';

export const handler = async (
  event: APIGatewayProxyEvent,
  context: Context
): Promise<APIGatewayProxyResult> => {
  console.log('=== Lambda Function Start ===');
  
  try {
    // Initialize Secrets Manager client
    const secretsManager = new SecretsManagerClient({
      region: 'us-west-1'
    });
    
    /*
    // Get Firebase credentials from Secrets Manager
    console.log('Retrieving Firebase credentials from Secrets Manager...');
    const firebaseResponse = await secretsManager.send(
      new GetSecretValueCommand({
        SecretId: process.env.FIREBASE_SECRET_ARN
      })
    );
    const firebaseCredentials = JSON.parse(firebaseResponse.SecretString || '{}');
    
    // Set Firebase environment variables
    process.env.FIREBASE_PROJECT_ID = firebaseCredentials.project_id;
    process.env.FIREBASE_CLIENT_EMAIL = firebaseCredentials.client_email;
    process.env.FIREBASE_PRIVATE_KEY = firebaseCredentials.private_key;

    console.log('Successfully retrieved Firebase credentials');

    // Authenticate request
    const authResult = await authMiddleware(event);
    if (authResult.statusCode === 401) {
      return authResult;
    }
    */
   
    // Get database credentials
    console.log('Retrieving database password from Secrets Manager...');
    // Get database password from Secrets Manager
    const dbResponse = await secretsManager.send(
      new GetSecretValueCommand({
        SecretId: process.env.RDS_MASTER_SECRET_ARN
      })
    );
    console.log('Successfully retrieved database password');
    
    const { password } = JSON.parse(dbResponse.SecretString || '{}');
    const encodedPassword = encodeURIComponent(password);

    // Construct database URL for Prisma
    const databaseUrl = `postgresql://${process.env.DB_USER}:${encodedPassword}@${process.env.DB_HOST}:5432/${process.env.DB_NAME}?schema=public&sslmode=require`;
    process.env.DATABASE_URL = databaseUrl;
    
    // Import Prisma after setting DATABASE_URL
    const prisma = (await import('./prisma/client')).default;

    // Test connection with Prisma
    console.log('Testing database connection...');
    const result = await prisma.$queryRaw`SELECT 1`;
    console.log('Database connection successful');

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Successfully connected to database',
        queryResult: result
      })
    };
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : 'Unknown error');
    console.error('Stack:', error instanceof Error ? error.stack : 'No stack trace');
    
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error processing request',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
};

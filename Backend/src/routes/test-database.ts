// This is a test route to check if the database connection is working

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { initializeDatabase } from '../config/database';

export const handleTestDatabase = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // Initialize database connection
    const prisma = await initializeDatabase();

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
    console.error('Database test error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Error testing database connection',
        error: error instanceof Error ? error.message : 'Unknown error'
      })
    };
  }
}; 
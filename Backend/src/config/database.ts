// This file is responsible for initializing the database connection

import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
// NOTE: We will import the shared Prisma singleton only *after* DATABASE_URL
// is guaranteed to be set (important for production where we fetch the secret).

const isDevelopment = process.env.NODE_ENV === 'development';

export const initializeDatabase = async () => {
  try {
    if (isDevelopment) {
      // In dev we simply return the shared singleton – no extra connections
      const { prisma } = await import('../prisma/client');
      return prisma;
    }

    // Production configuration using AWS Secrets Manager
    console.log('Using production database configuration...');
    const secretsManager = new SecretsManagerClient({
      region: 'us-west-1'
    });
   
    // Get database credentials
    console.log('Retrieving database password from Secrets Manager...');

    if (!process.env.RDS_MASTER_SECRET_ARN) {
      throw new Error("RDS_MASTER_SECRET_ARN is not set.");
    }
    
    const dbResponse = await secretsManager.send(
      new GetSecretValueCommand({
        SecretId: process.env.RDS_MASTER_SECRET_ARN
      })
    );
    console.log('Successfully retrieved database password');
    
    const { password } = JSON.parse(dbResponse.SecretString || '{}');
    const encodedPassword = encodeURIComponent(password);

    // Construct database URL for Prisma
    console.log('Constructing database URL...');
    // Use connection_limit=1 to avoid exhausting DB connections per Lambda container.
    const databaseUrl = `postgresql://${process.env.DB_USER}:${encodedPassword}@${process.env.DB_HOST}:5432/${process.env.DB_NAME}?schema=public&sslmode=require&connection_limit=1`;
    process.env.DATABASE_URL = databaseUrl;
    
    // After constructing DATABASE_URL, import the singleton (first import will
    // read the now-set DATABASE_URL) and return it.
    const { prisma } = await import('../prisma/client');
    return prisma;
  } catch (error) {
    console.error('Database initialization error:', error);
    throw error;
  }
}; 
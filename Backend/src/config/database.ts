// This file is responsible for initializing the database connection

import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const isDevelopment = process.env.NODE_ENV === 'development';

export const initializeDatabase = async () => {
  try {
    if (isDevelopment) {
      // In development, use the local database URL from .env
      console.log('Using development database configuration...');
      const { PrismaClient } = await import('@prisma/client');
      const prisma = new PrismaClient();
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
    const databaseUrl = `postgresql://${process.env.DB_USER}:${encodedPassword}@${process.env.DB_HOST}:5432/${process.env.DB_NAME}?schema=public&sslmode=require`;
    process.env.DATABASE_URL = databaseUrl;
    
    // Import Prisma after setting DATABASE_URL in production
    const { PrismaClient } = await import('@prisma/client');
    const prisma = new PrismaClient();
    
    return prisma;
  } catch (error) {
    console.error('Database initialization error:', error);
    throw error;
  }
}; 
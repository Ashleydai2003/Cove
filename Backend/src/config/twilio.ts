/**
 * Twilio Configuration - API Key Only
 * 
 * This module initializes the Twilio client for sending SMS notifications.
 * 
 * SECURITY: Uses Twilio API Keys for authentication
 * - API Keys provide scoped access and can be rotated independently
 * - More secure than using Account Auth Token (master password)
 * - Supports key revocation without affecting other credentials
 * 
 * Required credentials:
 * - TWILIO_ACCOUNT_SID: Your Twilio Account identifier
 * - TWILIO_API_KEY_SID: API Key identifier (starts with SK...)
 * - TWILIO_API_KEY_SECRET: API Key secret
 * - TWILIO_PHONE_NUMBER: Your Twilio phone number
 * 
 * Environment setup:
 * - Development: Uses environment variables from env.development
 * - Production: Fetches credentials from AWS Secrets Manager
 * 
 * To create API Keys:
 * 1. Go to https://console.twilio.com/us1/account/keys-credentials/api-keys
 * 2. Click "Create API Key"
 * 3. Save the SID and Secret
 */

import twilio from 'twilio';
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

const isDevelopment = process.env.NODE_ENV === 'development';

// Cache for Twilio credentials
let twilioCredentials: {
  accountSid: string;
  apiKeySid: string;
  apiKeySecret: string;
  phoneNumber: string;
} | null = null;

let twilioClient: ReturnType<typeof twilio> | null = null;

/**
 * Initialize and fetch Twilio credentials from AWS Secrets Manager (production only)
 */
const initializeTwilioCredentials = async () => {
  // If already initialized, return cached credentials
  if (twilioCredentials) {
    return twilioCredentials;
  }

  // In development, use environment variables
  if (isDevelopment) {
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const apiKeySid = process.env.TWILIO_API_KEY_SID;
    const apiKeySecret = process.env.TWILIO_API_KEY_SECRET;
    const phoneNumber = process.env.TWILIO_PHONE_NUMBER;

    if (!accountSid || !apiKeySid || !apiKeySecret || !phoneNumber) {
      console.log('[Twilio] Not configured in development - SMS notifications will be logged only');
      console.log('[Twilio] Required: TWILIO_ACCOUNT_SID, TWILIO_API_KEY_SID, TWILIO_API_KEY_SECRET, TWILIO_PHONE_NUMBER');
      return null;
    }

    twilioCredentials = { accountSid, apiKeySid, apiKeySecret, phoneNumber };
    console.log('[Twilio] Initialized with API Key (development)');
    return twilioCredentials;
  }

  // Production: Fetch from AWS Secrets Manager
  try {
    const secretsManager = new SecretsManagerClient({
      region: 'us-west-1'
    });

    console.log('[Twilio] Retrieving API Key credentials from AWS Secrets Manager...');
    
    const response = await secretsManager.send(
      new GetSecretValueCommand({
        SecretId: 'twilio-credentials',
        VersionStage: 'AWSCURRENT',
      })
    );

    if (!response.SecretString) {
      throw new Error('Failed to retrieve Twilio credentials from Secrets Manager');
    }

    const credentials = JSON.parse(response.SecretString);
    
    // Validate required fields
    const requiredFields = ['TWILIO_ACCOUNT_SID', 'TWILIO_API_KEY_SID', 'TWILIO_API_KEY_SECRET', 'TWILIO_PHONE_NUMBER'];
    const missingFields = requiredFields.filter(field => !credentials[field]);
    
    if (missingFields.length > 0) {
      throw new Error(`Missing required Twilio credentials in Secrets Manager: ${missingFields.join(', ')}`);
    }

    twilioCredentials = {
      accountSid: credentials.TWILIO_ACCOUNT_SID,
      apiKeySid: credentials.TWILIO_API_KEY_SID,
      apiKeySecret: credentials.TWILIO_API_KEY_SECRET,
      phoneNumber: credentials.TWILIO_PHONE_NUMBER,
    };

    console.log('[Twilio] Successfully retrieved API Key credentials from Secrets Manager');
    return twilioCredentials;
  } catch (error) {
    console.error('[Twilio] Error retrieving credentials from Secrets Manager:', error);
    return null;
  }
};

/**
 * Initialize Twilio client with API Key
 * 
 * Uses the recommended authentication method:
 *   twilio(apiKeySid, apiKeySecret, { accountSid })
 */
export const getTwilioClient = async () => {
  // Return cached client if available
  if (twilioClient) {
    return twilioClient;
  }

  const credentials = await initializeTwilioCredentials();
  
  if (!credentials) {
    return null;
  }

  // Initialize with API Key
  twilioClient = twilio(
    credentials.apiKeySid,
    credentials.apiKeySecret,
    { accountSid: credentials.accountSid }
  );
  
  console.log('[Twilio] Client initialized with API Key');
  return twilioClient;
};

/**
 * Get the configured Twilio phone number
 */
export const getTwilioPhoneNumber = async (): Promise<string | null> => {
  const credentials = await initializeTwilioCredentials();
  return credentials?.phoneNumber || null;
};

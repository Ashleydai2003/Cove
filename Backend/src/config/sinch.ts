/**
 * Sinch SMS Configuration - REST API
 * 
 * This module initializes the Sinch SMS client for sending SMS notifications.
 * 
 * SECURITY: Uses Sinch Service Plan ID and API Token
 * - API Token provides authentication for REST API requests
 * - More flexible than traditional SDK approaches
 * - Supports token rotation without affecting other credentials
 * 
 * Required credentials:
 * - SINCH_SERVICE_PLAN_ID: Your Sinch Service Plan identifier
 * - SINCH_API_TOKEN: API Token for authentication
 * - SINCH_PHONE_NUMBER: Your Sinch phone number
 * - SINCH_REGION: The region for your Sinch account (us or eu)
 * 
 * Environment setup:
 * - Development: Uses environment variables from env.development
 * - Production: Fetches credentials from AWS Secrets Manager
 * 
 * To get your credentials:
 * 1. Go to https://dashboard.sinch.com/sms/api/rest
 * 2. Find your Service Plan ID and API Token
 * 3. Assign a phone number to your service plan
 * 
 * Documentation: https://developers.sinch.com/docs/sms/getting-started/node/send-sms/
 */

import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
import axios, { AxiosInstance } from 'axios';

const isDevelopment = process.env.NODE_ENV === 'development';

// Cache for Sinch credentials
let sinchCredentials: {
  servicePlanId: string;
  apiToken: string;
  phoneNumber: string;
  region: string;
} | null = null;

let sinchClient: AxiosInstance | null = null;

/**
 * Initialize and fetch Sinch credentials from AWS Secrets Manager (production only)
 */
const initializeSinchCredentials = async () => {
  // If already initialized, return cached credentials
  if (sinchCredentials) {
    return sinchCredentials;
  }

  // In development, use environment variables
  if (isDevelopment) {
    const servicePlanId = process.env.SINCH_SERVICE_PLAN_ID;
    const apiToken = process.env.SINCH_API_TOKEN;
    const phoneNumber = process.env.SINCH_PHONE_NUMBER;
    const region = process.env.SINCH_REGION || 'us';

    if (!servicePlanId || !apiToken || !phoneNumber) {
      console.log('[Sinch] Not configured in development - SMS notifications will be logged only');
      console.log('[Sinch] Required: SINCH_SERVICE_PLAN_ID, SINCH_API_TOKEN, SINCH_PHONE_NUMBER');
      return null;
    }

    sinchCredentials = { servicePlanId, apiToken, phoneNumber, region };
    console.log('[Sinch] Initialized with API Token (development)');
    return sinchCredentials;
  }

  // Production: Fetch from AWS Secrets Manager
  try {
    const secretsManager = new SecretsManagerClient({
      region: 'us-west-1'
    });

    console.log('[Sinch] Retrieving API credentials from AWS Secrets Manager...');
    
    const response = await secretsManager.send(
      new GetSecretValueCommand({
        SecretId: 'sinch-credentials',
        VersionStage: 'AWSCURRENT',
      })
    );

    if (!response.SecretString) {
      throw new Error('Failed to retrieve Sinch credentials from Secrets Manager');
    }

    const credentials = JSON.parse(response.SecretString);
    
    // Validate required fields
    const requiredFields = ['SINCH_SERVICE_PLAN_ID', 'SINCH_API_TOKEN', 'SINCH_PHONE_NUMBER'];
    const missingFields = requiredFields.filter(field => !credentials[field]);
    
    if (missingFields.length > 0) {
      throw new Error(`Missing required Sinch credentials in Secrets Manager: ${missingFields.join(', ')}`);
    }

    sinchCredentials = {
      servicePlanId: credentials.SINCH_SERVICE_PLAN_ID,
      apiToken: credentials.SINCH_API_TOKEN,
      phoneNumber: credentials.SINCH_PHONE_NUMBER,
      region: credentials.SINCH_REGION || 'us',
    };

    console.log('[Sinch] Successfully retrieved API credentials from Secrets Manager');
    return sinchCredentials;
  } catch (error) {
    console.error('[Sinch] Error retrieving credentials from Secrets Manager:', error);
    return null;
  }
};

/**
 * Initialize Sinch HTTP client with axios
 * 
 * Creates an axios instance configured for Sinch REST API
 */
export const getSinchClient = async (): Promise<AxiosInstance | null> => {
  // Return cached client if available
  if (sinchClient) {
    return sinchClient;
  }

  const credentials = await initializeSinchCredentials();
  
  if (!credentials) {
    return null;
  }

  // Determine base URL based on region
  const baseURL = credentials.region === 'eu' 
    ? 'https://eu.sms.api.sinch.com/xms/v1'
    : 'https://us.sms.api.sinch.com/xms/v1';

  // Initialize axios client with Sinch configuration
  sinchClient = axios.create({
    baseURL: `${baseURL}/${credentials.servicePlanId}`,
    headers: {
      'Authorization': `Bearer ${credentials.apiToken}`,
      'Content-Type': 'application/json'
    }
  });
  
  console.log('[Sinch] HTTP Client initialized with API Token');
  return sinchClient;
};

/**
 * Get the configured Sinch phone number
 */
export const getSinchPhoneNumber = async (): Promise<string | null> => {
  const credentials = await initializeSinchCredentials();
  return credentials?.phoneNumber || null;
};

/**
 * Get the Sinch service plan ID
 */
export const getSinchServicePlanId = async (): Promise<string | null> => {
  const credentials = await initializeSinchCredentials();
  return credentials?.servicePlanId || null;
};

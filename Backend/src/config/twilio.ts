/**
 * Twilio Configuration
 * 
 * This module initializes the Twilio client for sending SMS notifications.
 * Environment variables required:
 * - TWILIO_ACCOUNT_SID: Your Twilio Account SID
 * - TWILIO_AUTH_TOKEN: Your Twilio Auth Token
 * - TWILIO_PHONE_NUMBER: Your Twilio phone number (E.164 format, e.g., +15551234567)
 */

import twilio from 'twilio';

/**
 * Initialize Twilio client
 * Returns null if credentials are not configured
 */
export const getTwilioClient = () => {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const phoneNumber = process.env.TWILIO_PHONE_NUMBER;

  // Return null if Twilio is not configured (e.g., in development)
  if (!accountSid || !authToken || !phoneNumber) {
    console.log('[Twilio] Not configured - SMS notifications will be logged only');
    return null;
  }

  return twilio(accountSid, authToken);
};

/**
 * Get the configured Twilio phone number
 */
export const getTwilioPhoneNumber = (): string | null => {
  return process.env.TWILIO_PHONE_NUMBER || null;
};

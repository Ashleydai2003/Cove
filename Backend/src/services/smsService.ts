/**
 * SMS Notification Service
 * 
 * This service handles sending SMS notifications via Sinch REST API.
 * It provides a clean interface for sending different types of SMS messages
 * and handles errors gracefully.
 * 
 * Key features:
 * - Environment-aware (logs in dev, sends in production)
 * - Phone number validation and formatting
 * - Graceful error handling
 * - Type-safe message templates
 * 
 * Documentation: https://developers.sinch.com/docs/sms/getting-started/node/send-sms/
 */

import { getSinchClient, getSinchPhoneNumber } from '../config/sinch';

/**
 * SMS notification types
 * Each type has a specific template and use case
 */
export enum SMSNotificationType {
  RSVP_APPROVED = 'RSVP_APPROVED',
  RSVP_DECLINED = 'RSVP_DECLINED',
  STOP_KEYWORD = 'STOP_KEYWORD',
  HELP_KEYWORD = 'HELP_KEYWORD',
}

/**
 * Parameters for RSVP approved SMS
 */
interface RSVPApprovedParams {
  eventName: string;
  eventId: string;
}

/**
 * Parameters for RSVP declined SMS
 */
interface RSVPDeclinedParams {
  eventName: string;
}

/**
 * Parameters for keyword responses
 */
interface KeywordParams {
  userPhone: string;
}

/**
 * Union type for all SMS parameters
 */
type SMSParams = RSVPApprovedParams | RSVPDeclinedParams | KeywordParams;

/**
 * Format a phone number to E.164 format
 * E.164 format: +[country code][number] (e.g., +15551234567)
 * 
 * @param phone - Phone number in any format
 * @returns Formatted phone number or null if invalid
 */
const formatPhoneNumber = (phone: string): string | null => {
  // Remove all non-digit characters
  const digitsOnly = phone.replace(/\D/g, '');
  
  // If already has country code (11 digits for US), add +
  if (digitsOnly.length === 11 && digitsOnly.startsWith('1')) {
    return `+${digitsOnly}`;
  }
  
  // If 10 digits (US number without country code), add +1
  if (digitsOnly.length === 10) {
    return `+1${digitsOnly}`;
  }
  
  // If already starts with +, return as-is
  if (phone.startsWith('+')) {
    return phone;
  }
  
  // Invalid format
  console.warn(`[SMS] Invalid phone number format: ${phone}`);
  return null;
};

/**
 * Generate SMS message based on notification type
 * 
 * @param type - Type of SMS notification
 * @param params - Parameters for the message template
 * @returns Formatted SMS message
 */
const generateMessage = (type: SMSNotificationType, params: SMSParams): string => {
  switch (type) {
    case SMSNotificationType.RSVP_APPROVED:
      const approvedParams = params as RSVPApprovedParams;
      const eventLink = `https://www.coveapp.co/events/${approvedParams.eventId}`;
      return `Your RSVP to ${approvedParams.eventName} has been approved! Event details and guest list: ${eventLink}\n\nReply STOP to opt out, HELP for help. Msg&data rates may apply.`;
    
    case SMSNotificationType.RSVP_DECLINED:
      const declinedParams = params as RSVPDeclinedParams;
      return `Your RSVP to "${declinedParams.eventName}" was declined. The event may be at capacity.\n\nReply STOP to opt out, HELP for help. Msg&data rates may apply.`;
    
    case SMSNotificationType.STOP_KEYWORD:
      return 'You have been unsubscribed from Cove SMS notifications. You will no longer receive event updates via text. Reply HELP for assistance.';
    
    case SMSNotificationType.HELP_KEYWORD:
      return 'Cove SMS Help:\n• RSVP confirmations and event updates\n• Up to 3 msgs per event\n• Reply STOP to unsubscribe\n• Visit coveapp.co for support\n\nMsg&data rates may apply.';
    
    default:
      return 'You have a new notification from Cove.';
  }
};

/**
 * Send an SMS notification
 * 
 * This is the main function for sending SMS messages.
 * It handles phone formatting, message generation, and error handling.
 * 
 * @param phoneNumber - Recipient's phone number
 * @param type - Type of notification to send
 * @param params - Parameters for the message template
 * @returns Promise<boolean> - True if sent successfully, false otherwise
 */
export const sendSMS = async (
  phoneNumber: string,
  type: SMSNotificationType,
  params: SMSParams
): Promise<boolean> => {
  try {
    // Format phone number
    const formattedPhone = formatPhoneNumber(phoneNumber);
    if (!formattedPhone) {
      console.error('[SMS] Invalid phone number, cannot send SMS');
      return false;
    }

    // Generate message
    const message = generateMessage(type, params);

    // Get Sinch client and phone number (async in production)
    const sinchClient = await getSinchClient();
    const sinchPhoneNumber = await getSinchPhoneNumber();

    // If Sinch not configured (development), just log
    if (!sinchClient || !sinchPhoneNumber) {
      console.log('[SMS] [DEVELOPMENT MODE] Would send SMS:');
      console.log(`  To: ${formattedPhone}`);
      console.log(`  Type: ${type}`);
      console.log(`  Message: ${message}`);
      return true;
    }

    // Send SMS via Sinch REST API
    console.log(`[SMS] Sending ${type} to ${formattedPhone}`);
    
    // Prepare Sinch batch SMS request
    const smsData = {
      from: sinchPhoneNumber,
      to: [formattedPhone],
      body: message
    };

    const response = await sinchClient.post('/batches', smsData);

    console.log(`[SMS] Message sent successfully. Batch ID: ${response.data.id}`);
    return true;

  } catch (error) {
    console.error('[SMS] Error sending SMS:', error);
    if (error instanceof Error && 'response' in error) {
      const axiosError = error as any;
      console.error('[SMS] Sinch API Error:', axiosError.response?.data);
    }
    return false;
  }
};

/**
 * Send RSVP approval notification
 * 
 * Convenience function for sending RSVP approved notifications.
 * 
 * @param phoneNumber - Recipient's phone number
 * @param eventName - Name of the event
 * @param eventId - ID of the event for generating the share link
 * @returns Promise<boolean> - True if sent successfully
 */
export const sendRSVPApprovedSMS = async (
  phoneNumber: string,
  eventName: string,
  eventId: string
): Promise<boolean> => {
  return sendSMS(phoneNumber, SMSNotificationType.RSVP_APPROVED, {
    eventName,
    eventId,
  });
};

/**
 * Send RSVP declined notification
 * 
 * Convenience function for sending RSVP declined notifications.
 * 
 * @param phoneNumber - Recipient's phone number
 * @param eventName - Name of the event
 * @returns Promise<boolean> - True if sent successfully
 */
export const sendRSVPDeclinedSMS = async (
  phoneNumber: string,
  eventName: string
): Promise<boolean> => {
  return sendSMS(phoneNumber, SMSNotificationType.RSVP_DECLINED, {
    eventName,
  });
};

/**
 * Send STOP keyword response
 * 
 * Sends confirmation when user texts STOP to unsubscribe.
 * 
 * @param phoneNumber - Recipient's phone number
 * @returns Promise<boolean> - True if sent successfully
 */
export const sendSTOPResponse = async (
  phoneNumber: string
): Promise<boolean> => {
  return sendSMS(phoneNumber, SMSNotificationType.STOP_KEYWORD, {
    userPhone: phoneNumber,
  });
};

/**
 * Send HELP keyword response
 * 
 * Sends help information when user texts HELP.
 * 
 * @param phoneNumber - Recipient's phone number
 * @returns Promise<boolean> - True if sent successfully
 */
export const sendHELPResponse = async (
  phoneNumber: string
): Promise<boolean> => {
  return sendSMS(phoneNumber, SMSNotificationType.HELP_KEYWORD, {
    userPhone: phoneNumber,
  });
};

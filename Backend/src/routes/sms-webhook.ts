/**
 * SMS Webhook Handler for 10DLC Compliance
 * 
 * This endpoint handles incoming SMS messages for STOP/HELP keyword processing.
 * Required for 10DLC compliance to handle opt-out requests and help requests.
 * 
 * 10DLC Requirements:
 * - Must respond to STOP keyword within 5 minutes
 * - Must respond to HELP keyword with program information
 * - Must maintain opt-out list to prevent future messages
 * 
 * Sinch Webhook Documentation:
 * https://developers.sinch.com/docs/sms/webhooks
 */

import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { PrismaClient } from '@prisma/client';
import { sendSTOPResponse, sendHELPResponse } from '../services/smsService';
import crypto from 'crypto';

const prisma = new PrismaClient();

// Rate limiting: Track requests per IP
const rateLimitMap = new Map<string, { count: number; resetTime: number }>();
const RATE_LIMIT_WINDOW = 60 * 1000; // 1 minute
const RATE_LIMIT_MAX_REQUESTS = 10; // 10 requests per minute

/**
 * Check if request is within rate limits
 * 
 * @param ip - Client IP address
 * @returns boolean - True if within limits
 */
const checkRateLimit = (ip: string): boolean => {
  const now = Date.now();
  const clientData = rateLimitMap.get(ip);
  
  if (!clientData || now > clientData.resetTime) {
    // Reset or create new entry
    rateLimitMap.set(ip, { count: 1, resetTime: now + RATE_LIMIT_WINDOW });
    return true;
  }
  
  if (clientData.count >= RATE_LIMIT_MAX_REQUESTS) {
    return false;
  }
  
  clientData.count++;
  return true;
};

/**
 * Verify Sinch webhook signature for security
 * 
 * @param payload - Raw request body
 * @param signature - X-Sinch-Signature header
 * @param secret - Sinch webhook secret
 * @returns boolean - True if signature is valid
 */
const verifySinchSignature = (payload: string, signature: string, secret: string): boolean => {
  try {
    // Sinch uses HMAC-SHA256 with the secret
    const expectedSignature = crypto
      .createHmac('sha256', secret)
      .update(payload, 'utf8')
      .digest('hex');
    
    // Compare signatures (constant-time comparison)
    return crypto.timingSafeEqual(
      Buffer.from(signature, 'hex'),
      Buffer.from(expectedSignature, 'hex')
    );
  } catch (error) {
    console.error('[SMS Webhook] Signature verification error:', error);
    return false;
  }
};

/**
 * Validate and normalize phone number to E.164 format
 * 
 * @param phone - Raw phone number
 * @returns string | null - Normalized E.164 format or null if invalid
 */
const normalizePhoneNumber = (phone: string): string | null => {
  if (!phone) return null;
  
  // Remove all non-digit characters
  const digitsOnly = phone.replace(/\D/g, '');
  
  // Must be 10-15 digits (international format)
  if (digitsOnly.length < 10 || digitsOnly.length > 15) {
    return null;
  }
  
  // If 10 digits (US number), add +1
  if (digitsOnly.length === 10) {
    return `+1${digitsOnly}`;
  }
  
  // If 11 digits and starts with 1 (US with country code), add +
  if (digitsOnly.length === 11 && digitsOnly.startsWith('1')) {
    return `+${digitsOnly}`;
  }
  
  // If already has country code, add +
  if (digitsOnly.length > 10) {
    return `+${digitsOnly}`;
  }
  
  return null;
};

/**
 * Handle incoming SMS webhook from Sinch
 * 
 * POST /api/sms-webhook
 * 
 * Expected payload from Sinch:
 * {
 *   "type": "mo_text",
 *   "to": "+1234567890",
 *   "from": "+0987654321", 
 *   "body": "STOP",
 *   "timestamp": "2024-01-01T00:00:00Z"
 * }
 */
export const handleSMSWebhook = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    // SECURITY: Rate limiting
    const clientIP = event.requestContext?.identity?.sourceIp || 'unknown';
    if (!checkRateLimit(clientIP)) {
      console.error('[SMS Webhook] Rate limit exceeded for IP:', clientIP);
      return {
        statusCode: 429,
        body: JSON.stringify({ error: 'Rate limit exceeded' })
      };
    }
    
    // SECURITY: Verify webhook signature
    const signature = event.headers['X-Sinch-Signature'] || event.headers['x-sinch-signature'];
    const webhookSecret = process.env.SINCH_WEBHOOK_SECRET;
    
    if (!signature || !webhookSecret) {
      console.error('[SMS Webhook] Missing signature or webhook secret');
      return {
        statusCode: 401,
        body: JSON.stringify({ error: 'Unauthorized' })
      };
    }
    
    // Verify signature
    if (!verifySinchSignature(event.body || '', signature, webhookSecret)) {
      console.error('[SMS Webhook] Invalid signature');
      return {
        statusCode: 401,
        body: JSON.stringify({ error: 'Invalid signature' })
      };
    }
    
    // Parse the request body
    const body = event.body ? JSON.parse(event.body) : {};
    const { type, to, from, body: messageBody } = body;

    // Only process incoming text messages
    if (type !== 'mo_text') {
      console.log('[SMS Webhook] Ignoring non-text message:', type);
      return {
        statusCode: 200,
        body: JSON.stringify({ status: 'ignored' })
      };
    }

    // SECURITY: Validate and normalize phone numbers
    const normalizedUserPhone = normalizePhoneNumber(from);
    const normalizedSinchPhone = normalizePhoneNumber(to);

    if (!normalizedUserPhone || !messageBody) {
      console.error('[SMS Webhook] Invalid phone number or missing message:', { 
        from, 
        normalizedUserPhone, 
        messageBody 
      });
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Invalid phone number or missing message' })
      };
    }

    // SECURITY: Validate message body
    if (typeof messageBody !== 'string' || messageBody.length > 160) {
      console.error('[SMS Webhook] Invalid message body:', { 
        type: typeof messageBody, 
        length: messageBody?.length 
      });
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Invalid message body' })
      };
    }

    // Normalize the message body
    const message = messageBody.trim().toUpperCase();

    console.log(`[SMS Webhook] Received from ${normalizedUserPhone}: "${message}"`);

    // Handle STOP keyword
    if (message === 'STOP') {
      try {
        // SECURITY: Use exact phone match instead of contains
        const user = await prisma.user.findFirst({
          where: {
            phone: normalizedUserPhone
          }
        });

        if (!user) {
          console.log(`[SMS Webhook] User not found for phone: ${normalizedUserPhone}`);
          // Still send STOP response for security
          await sendSTOPResponse(from);
          return {
            statusCode: 200,
            body: JSON.stringify({ 
              status: 'success', 
              action: 'unsubscribed' 
            })
          };
        }

        // Update specific user's SMS opt-in status
        await prisma.user.update({
          where: {
            id: user.id
          },
          data: {
            smsOptIn: false
          }
        });

        console.log(`[SMS Webhook] User ${user.id} (${normalizedUserPhone}) opted out of SMS`);

        // Send STOP confirmation
        await sendSTOPResponse(from);
        
        return {
          statusCode: 200,
          body: JSON.stringify({ 
            status: 'success', 
            action: 'unsubscribed' 
          })
        };
      } catch (dbError) {
        console.error('[SMS Webhook] Database error during STOP:', dbError);
        // Still send response even if DB update fails
        await sendSTOPResponse(from);
        return {
          statusCode: 200,
          body: JSON.stringify({ 
            status: 'success', 
            action: 'unsubscribed' 
          })
        };
      }
    }

    // Handle HELP keyword
    if (message === 'HELP') {
      try {
        await sendHELPResponse(from);
        console.log(`[SMS Webhook] Sent HELP response to ${normalizedUserPhone}`);
        return {
          statusCode: 200,
          body: JSON.stringify({ 
            status: 'success', 
            action: 'help_sent' 
          })
        };
      } catch (helpError) {
        console.error('[SMS Webhook] Error sending HELP response:', helpError);
        return {
          statusCode: 500,
          body: JSON.stringify({ error: 'Failed to send help response' })
        };
      }
    }

    // Handle other keywords or unknown messages
    console.log(`[SMS Webhook] Unknown message from ${normalizedUserPhone}: "${message}"`);
    
    // For unknown messages, send a brief help response
    try {
      await sendHELPResponse(from);
      return {
        statusCode: 200,
        body: JSON.stringify({ 
          status: 'success', 
          action: 'help_sent' 
        })
      };
    } catch (helpError) {
      console.error('[SMS Webhook] Error sending help for unknown message:', helpError);
      return {
        statusCode: 500,
        body: JSON.stringify({ error: 'Failed to send help response' })
      };
    }

  } catch (error) {
    console.error('[SMS Webhook] Unexpected error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
};

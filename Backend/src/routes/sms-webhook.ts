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

const prisma = new PrismaClient();

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

    // Format phone numbers
    const userPhone = from?.replace(/\D/g, '');
    const sinchPhone = to?.replace(/\D/g, '');

    if (!userPhone || !messageBody) {
      console.error('[SMS Webhook] Missing required fields:', { userPhone, messageBody });
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing required fields' })
      };
    }

    // Normalize the message body
    const message = messageBody.trim().toUpperCase();

    console.log(`[SMS Webhook] Received from ${userPhone}: "${message}"`);

    // Handle STOP keyword
    if (message === 'STOP') {
      try {
        // Update user's SMS opt-in status in database
        await prisma.user.updateMany({
          where: {
            phone: {
              contains: userPhone
            }
          },
          data: {
            smsOptIn: false
          }
        });

        console.log(`[SMS Webhook] User ${userPhone} opted out of SMS`);

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
        console.log(`[SMS Webhook] Sent HELP response to ${userPhone}`);
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
    console.log(`[SMS Webhook] Unknown message from ${userPhone}: "${message}"`);
    
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

# SMS Notifications with Twilio

This document explains how SMS notifications work in the Cove backend and how to set them up.

## Overview

The SMS notification system sends text messages to users when their event RSVPs are approved or declined by event hosts. It uses Twilio as the SMS provider.

## Features

✅ **RSVP Approval Notifications** - Users receive an SMS when their RSVP is approved  
✅ **RSVP Decline Notifications** - Users receive an SMS when their RSVP is declined  
✅ **Automatic Phone Formatting** - Handles US phone numbers in various formats  
✅ **Environment-Aware** - Logs messages in development, sends in production  
✅ **Graceful Fallback** - Works without Twilio credentials (logs only)  
✅ **Error Handling** - Never blocks the main RSVP flow if SMS fails

## Architecture

```
┌─────────────────────────┐
│  RSVP Approval Endpoint │
│   (routes/event.ts)     │
└───────────┬─────────────┘
            │
            ├──> Push Notification (Firebase)
            │
            └──> SMS Notification (Twilio)
                        │
                        ▼
                ┌───────────────┐
                │  SMS Service  │
                │ (smsService)  │
                └───────┬───────┘
                        │
                        ▼
                ┌───────────────┐
                │ Twilio Config │
                │ (twilio.ts)   │
                └───────┬───────┘
                        │
                        ▼
                  Twilio API
```

## Files

### `/src/config/twilio.ts`
Configuration for Twilio client initialization. Handles environment variables and client setup.

### `/src/services/smsService.ts`
Main SMS service with message templates, phone formatting, and sending logic.

### `/src/routes/event.ts`
Integration point where SMS notifications are triggered on RSVP approval/decline.

## Setup Instructions

### 1. Get Twilio Credentials

Follow these steps to get your Twilio credentials:

#### Step 1: Create a Twilio Account

1. Go to **https://www.twilio.com/try-twilio**
2. Click **"Sign up"** or **"Start for free"**
3. Fill in your information:
   - Email address
   - Password
   - First and last name
4. Verify your email address
5. Complete the phone verification (Twilio will send you a code)

#### Step 2: Get Your Account SID and Auth Token

Once logged in to the Twilio Console:

1. Go to the **Twilio Console Dashboard**: https://console.twilio.com/
2. You'll see your **Account Info** section on the right side
3. Copy these two values:
   - **Account SID** - Starts with `AC...` (e.g., `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)
   - **Auth Token** - Click "View" to reveal it, then copy
   
   ```
   Account SID:  ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   Auth Token:   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

**Important**: Keep your Auth Token secret! Never commit it to version control.

#### Step 3: Get a Twilio Phone Number

You need a phone number to send SMS from:

1. In the Twilio Console, go to **Phone Numbers** > **Manage** > **Buy a number**
   - Or visit: https://console.twilio.com/us1/develop/phone-numbers/manage/search
   
2. Select your country (e.g., United States)

3. Check the **SMS** capability checkbox

4. Click **Search** to see available numbers

5. Choose a number you like and click **Buy**

6. Confirm the purchase (free trial accounts get $15 credit)

7. Once purchased, go to **Phone Numbers** > **Manage** > **Active numbers**
   - Or visit: https://console.twilio.com/us1/develop/phone-numbers/manage/incoming

8. Your phone number will be shown in **E.164 format**: `+15551234567`

9. Copy this number for your environment variables

#### Step 4: Verify Your Recipient Phone Numbers (Trial Accounts Only)

If using a **trial account**, you must verify phone numbers before sending SMS:

1. Go to **Phone Numbers** > **Manage** > **Verified Caller IDs**
   - Or visit: https://console.twilio.com/us1/develop/phone-numbers/manage/verified

2. Click **Add a new Caller ID**

3. Enter the phone number you want to send SMS to

4. Choose **SMS** as verification method

5. Enter the verification code sent to that number

**Note**: Production accounts (after upgrading) don't need this step.

#### Quick Reference - Where to Find Everything:

| Credential | Location | Format |
|------------|----------|--------|
| **Account SID** | Console Dashboard → Account Info | `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| **Auth Token** | Console Dashboard → Account Info (click "View") | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` |
| **Phone Number** | Phone Numbers → Active Numbers | `+15551234567` |

### 2. Add Environment Variables

Add these to your environment configuration:

**For Development** (`env.development`):
```bash
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+15551234567  # Your Twilio number in E.164 format
```

**For Production** (`env.production`):
```bash
TWILIO_ACCOUNT_SID=your_account_sid_here
TWILIO_AUTH_TOKEN=your_auth_token_here
TWILIO_PHONE_NUMBER=+15551234567
```

**AWS Secrets Manager** (for production deployment):
Add these secrets to your AWS Secrets Manager configuration.

### 3. Phone Number Format

The system expects phone numbers in **E.164 format**:
- Format: `+[country code][number]`
- Example: `+15551234567` (US number)
- The service automatically formats US numbers

## Usage

### Sending RSVP Approved SMS

```typescript
import { sendRSVPApprovedSMS } from '../services/smsService';

await sendRSVPApprovedSMS(
  userPhoneNumber,   // '+15551234567'
  eventName,         // 'Summer Rooftop Party'
  eventDate          // 'Sat, Jun 15, 7:00 PM'
);
```

**Message Template:**
```
🎉 Your RSVP to "Summer Rooftop Party" on Sat, Jun 15, 7:00 PM has been approved! See you there!
```

### Sending RSVP Declined SMS

```typescript
import { sendRSVPDeclinedSMS } from '../services/smsService';

await sendRSVPDeclinedSMS(
  userPhoneNumber,   // '+15551234567'
  eventName          // 'Summer Rooftop Party'
);
```

**Message Template:**
```
Your RSVP to "Summer Rooftop Party" was declined. The event may be at capacity.
```

## Development vs Production

### Development Mode
- **Without Twilio credentials**: Logs SMS messages to console
- **With Twilio credentials**: Can send actual SMS (useful for testing)
- All SMS attempts are logged with `[SMS]` prefix

### Production Mode
- **Requires Twilio credentials**: Must be configured in environment
- Sends actual SMS messages to users
- Failures are logged but don't block RSVP approval

## Error Handling

The SMS service is designed to **never block** the main RSVP flow:

```typescript
try {
  await sendRSVPApprovedSMS(phone, eventName, eventDate);
} catch (smsErr) {
  console.error('[SMS] Error sending notification:', smsErr);
  // RSVP approval continues even if SMS fails
}
```

## Monitoring & Debugging

### Log Messages

All SMS operations are logged with prefixes:

```
[SMS] Sending RSVP_APPROVED to +15551234567
[SMS] Message sent successfully. SID: SM1234567890abcdef
[SMS] [DEVELOPMENT MODE] Would send SMS:
  To: +15551234567
  Type: RSVP_APPROVED
  Message: 🎉 Your RSVP to "Summer Party" has been approved!
```

### Common Issues

#### Getting Twilio Credentials

**Issue**: Can't find Account SID and Auth Token
- **Solution**: Go to https://console.twilio.com/ - they're in the "Account Info" box on the right side of the dashboard

**Issue**: Auth Token is hidden
- **Solution**: Click the "View" button next to "Auth Token" to reveal it

**Issue**: Need to buy a phone number but seeing "Trial Account" warning
- **Solution**: Trial accounts get $15 free credit - you can buy a phone number with this credit. No payment required initially.

**Issue**: Can't send SMS to a phone number (trial account)
- **Solution**: Trial accounts can only send to verified numbers. Go to Phone Numbers → Verified Caller IDs and add the recipient's number.

**Issue**: Getting "geographical permissions" error
- **Solution**: By default, trial accounts can only send SMS within your country. Upgrade to send internationally.

#### Integration Issues

**Issue**: "Invalid phone number format"
- **Solution**: Ensure phone numbers in database are valid US numbers (10 digits) or in E.164 format

**Issue**: "Twilio not configured" in logs
- **Solution**: Add TWILIO_* environment variables to your env file. Service will work in log-only mode without them.

**Issue**: SMS not sending in production
- **Solution**: 
  1. Check Twilio account balance (https://console.twilio.com/billing/overview)
  2. Verify phone number capabilities include SMS
  3. Check CloudWatch logs for specific error messages

**Issue**: "Authentication Error" from Twilio
- **Solution**: 
  1. Verify TWILIO_ACCOUNT_SID starts with "AC"
  2. Verify TWILIO_AUTH_TOKEN is correct (re-copy from console)
  3. Check for extra spaces in environment variables

**Issue**: Messages say "Sent from your Twilio trial account"
- **Solution**: This is normal for trial accounts. Upgrade to remove this prefix.

## Testing

### Manual Testing

1. **Development Mode** (without credentials):
   ```bash
   npm run dev
   # Approve an RSVP, check console for logged SMS
   ```

2. **Development Mode** (with credentials):
   ```bash
   # Add Twilio credentials to env.development
   npm run dev
   # Approve an RSVP, receive actual SMS
   ```

3. **Production Mode**:
   ```bash
   # Ensure credentials are in env.production or AWS Secrets
   npm run start:prod
   ```

### Test Phone Numbers

Twilio provides test credentials and phone numbers for development:
- Test Account SID: Available in Twilio Console
- Test Phone Numbers: Twilio provides verified test numbers

## Cost Considerations

- **SMS Pricing**: ~$0.0079 per message (US)
- **Monthly Cost Estimate**: 
  - 100 RSVPs/month = ~$0.79
  - 1,000 RSVPs/month = ~$7.90
  - 10,000 RSVPs/month = ~$79.00

## Security

- ✅ Twilio credentials stored in environment variables
- ✅ Never logged or exposed in responses
- ✅ Phone numbers validated and formatted
- ✅ Rate limiting handled by Twilio

## Future Enhancements

Potential features to add:

- [ ] SMS for event reminders (24h before event)
- [ ] SMS for event cancellations
- [ ] SMS for event updates
- [ ] Customizable message templates
- [ ] SMS opt-out functionality
- [ ] International phone number support
- [ ] SMS delivery status tracking

## Support

For Twilio-specific issues:
- Twilio Docs: https://www.twilio.com/docs
- Twilio Support: https://support.twilio.com

For code issues:
- Check logs in CloudWatch (production)
- Check console output (development)
- Review error messages with `[SMS]` prefix

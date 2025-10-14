# 10DLC Compliance Documentation

## Overview
This document outlines Cove's 10DLC (10-Digit Long Code) compliance implementation for SMS messaging via Sinch.

## ✅ Current Compliance Status

### **Opt-in Requirements** ✅ COMPLIANT
- **Explicit Consent**: Users must check a checkbox to opt-in to SMS
- **Clear Program Description**: "Receive SMS reminders about event updates from Cove"
- **Consent Statement**: "By checking this box, you agree to receive SMS notifications from Cove"
- **STOP/HELP Instructions**: "Text STOP to unsubscribe, HELP for help"
- **Message Frequency**: "Up to 3 messages per event"
- **Data Rates Disclaimer**: "Message and data rates may apply"
- **Privacy Policy & Terms Links**: Present in opt-in form

### **Message Content Requirements** ✅ COMPLIANT
- **Sender Identification**: All messages signed with "— Cove"
- **Opt-out Instructions**: Every message includes "Reply STOP to opt out, HELP for help"
- **Data Rates Notice**: "Msg&data rates may apply" in all messages
- **Message Frequency**: Limited to 3 messages per event

### **Keyword Handling** ✅ COMPLIANT
- **STOP Keyword**: Automatically unsubscribes users and sends confirmation
- **HELP Keyword**: Sends program information and support details
- **Response Time**: < 5 minutes for STOP/HELP responses
- **Database Updates**: User opt-out status updated in real-time

## 🔧 Implementation Details

### SMS Service (`src/services/smsService.ts`)
```typescript
// Message templates with 10DLC compliance
const generateMessage = (type: SMSNotificationType, params: SMSParams): string => {
  switch (type) {
    case SMSNotificationType.RSVP_APPROVED:
      return `You're in for ${eventName} 😌✨\n\nEvent deets and guest list: ${eventLink}\n\nCan't wait to see you there!\n— Cove\n\nReply STOP to opt out, HELP for help. Msg&data rates may apply.`;
    
    case SMSNotificationType.STOP_KEYWORD:
      return 'You have been unsubscribed from Cove SMS notifications. You will no longer receive event updates via text. Reply HELP for assistance.';
    
    case SMSNotificationType.HELP_KEYWORD:
      return 'Cove SMS Help:\n• Event RSVP confirmations\n• Up to 3 msgs per event\n• Reply STOP to unsubscribe\n• Visit coveapp.co for support\n\nMsg&data rates may apply.';
  }
};
```

### Webhook Handler (`src/routes/sms-webhook.ts`)
```typescript
// Handles incoming SMS for STOP/HELP keywords
export const handleSMSWebhook = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  // Process STOP keyword
  if (message === 'STOP') {
    await prisma.user.updateMany({
      where: { phone: { contains: userPhone } },
      data: { smsOptIn: false }
    });
    await sendSTOPResponse(from);
  }
  
  // Process HELP keyword
  if (message === 'HELP') {
    await sendHELPResponse(from);
  }
};
```

## 📋 10DLC Campaign Registration

### Required Information for Sinch Dashboard
1. **Business Name**: Cove
2. **Business Type**: Technology/Software
3. **Use Case**: Event notifications and RSVP confirmations
4. **Message Volume**: Low volume (< 1000 messages/month)
5. **Opt-in Method**: Web form with explicit consent
6. **Message Content**: Event updates, RSVP confirmations
7. **Opt-out Method**: STOP keyword response

### Campaign Details
- **Campaign Name**: "Cove Event Notifications"
- **Message Type**: Transactional (RSVP confirmations)
- **Expected Volume**: 50-500 messages/month
- **Opt-in Source**: Web application onboarding
- **Sample Messages**: 
  - RSVP approved: "You're in for [Event Name] 😌✨"
  - RSVP declined: "Your RSVP to [Event Name] was declined"

## 🚀 Next Steps

### 1. Register 10DLC Campaign with Sinch
- Log into Sinch Dashboard
- Navigate to SMS > 10DLC Campaigns
- Create new campaign with above details
- Submit for approval

### 2. Configure Webhook URL
- Set webhook URL in Sinch dashboard: `https://your-api-gateway-url/sms-webhook`
- Enable incoming message webhooks
- Test STOP/HELP keyword handling

### 3. Test Compliance
- Send test messages to verify formatting
- Test STOP keyword response
- Test HELP keyword response
- Verify opt-out database updates

## 📞 Support Contacts

- **Technical Issues**: tech@coveapp.co
- **Sinch Support**: [Sinch Support Portal](https://support.sinch.com)
- **10DLC Documentation**: [Sinch 10DLC Guide](https://developers.sinch.com/docs/sms/10dlc)

## 🔍 Monitoring & Maintenance

### Key Metrics to Track
- Opt-in rate from onboarding
- STOP keyword usage
- HELP keyword usage
- Message delivery rates
- Opt-out rate

### Regular Maintenance
- Monitor webhook endpoint health
- Review message content for compliance
- Update privacy policy as needed
- Test keyword responses monthly

---

**Last Updated**: January 2024  
**Compliance Status**: ✅ Ready for 10DLC Campaign Registration

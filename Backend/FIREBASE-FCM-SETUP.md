# Firebase FCM Setup Guide

This guide covers the Firebase configuration needed for FCM push notifications to work properly in the messaging system.

## 🔧 Required Firebase Configuration

### **1. Firebase Console Setup**

#### **Enable Cloud Messaging**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `cove-40d9f`
3. Navigate to **Project Settings** → **Cloud Messaging**
4. Enable **Cloud Messaging** if not already enabled

#### **Configure iOS App**
1. In **Project Settings** → **General**
2. Under **Your apps**, find your iOS app
3. Click **Add app** if iOS app not listed
4. Download the updated `GoogleService-Info.plist`
5. Replace the existing file in your iOS project

### **2. iOS App Configuration**

#### **Update FirebaseSetup.swift**
The current setup needs FCM token registration:

```swift
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

class FirebaseSetup: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set messaging delegate
        Messaging.messaging().delegate = self
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound],
            completionHandler: { _, _ in }
        )
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        #if DEBUG
        // Use Firebase Auth emulator for local development
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        Log.debug("[Firebase] Using Auth emulator at localhost:9099")
        #endif
        
        return true
    }
    
    // MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Log.debug("Firebase registration token: \(String(describing: fcmToken))")
        
        // Send FCM token to your backend
        if let token = fcmToken {
            sendFCMTokenToBackend(token)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([[.banner, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        handleNotificationTap(userInfo)
        completionHandler()
    }
    
    // MARK: - Helper Methods
    
    private func sendFCMTokenToBackend(_ token: String) {
        // Send token to your backend API
        guard let url = URL(string: "YOUR_API_BASE_URL/update-fcm-token") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add your authentication header
        if let idToken = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["fcmToken": token]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Log.error("Failed to send FCM token: \(error)")
            } else {
                Log.debug("FCM token sent successfully")
            }
        }.resume()
    }
    
    private func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
        // Handle notification tap - navigate to appropriate screen
        if let threadId = userInfo["threadId"] as? String {
            // Navigate to the specific thread
            // This depends on your app's navigation structure
        }
    }
}
```

#### **Update Info.plist**
Add these keys to your `Info.plist`:

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
<key>FirebaseAutomaticScreenReportingEnabled</key>
<false/>
```

### **3. Firebase Admin SDK Configuration**

#### **Create Service Account**
1. Go to **Project Settings** → **Service Accounts**
2. Click **Generate new private key**
3. Download the JSON file
4. Create AWS Secrets Manager secret named `firebaseSDK`
5. Store the JSON content in the secret

#### **Verify Secret Content**
The secret should contain:
```json
{
  "type": "service_account",
  "project_id": "cove-40d9f",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@cove-40d9f.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40cove-40d9f.iam.gserviceaccount.com"
}
```

### **4. APNs Configuration**

#### **Development vs Production**
- **Development**: Uses development APNs certificates
- **Production**: Requires production APNs certificates

#### **APNs Authentication Key (Recommended)**
1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Go to **Keys** → **All**
4. Create a new key with **Apple Push Notifications service (APNs)** enabled
5. Download the `.p8` file
6. Note the **Key ID** and **Team ID**

#### **Upload to Firebase**
1. In Firebase Console, go to **Project Settings** → **Cloud Messaging**
2. Under **Apple apps**, click **Upload**
3. Upload your `.p8` file
4. Enter your **Key ID** and **Team ID**
5. Save the configuration

### **5. Testing FCM**

#### **Test Token Registration**
```bash
# Test the FCM token endpoint
curl -X POST https://your-api-gateway-url/update-fcm-token \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"fcmToken":"test_fcm_token_123"}'
```

#### **Test Push Notification**
```bash
# Test sending a notification
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test Message",
      "body": "This is a test notification"
    },
    "data": {
      "threadId": "test_thread",
      "type": "new_message"
    }
  }'
```

### **6. Environment-Specific Setup**

#### **Development Environment**
- Use development APNs certificates
- Test with development FCM tokens
- Use Firebase Auth emulator

#### **Production Environment**
- Use production APNs certificates
- Use production FCM tokens
- Ensure proper Firebase project configuration

### **7. Troubleshooting**

#### **Common Issues**

1. **"No valid 'aps-environment' entitlement"**
   - Check your app's entitlements file
   - Ensure `aps-environment` is set to `development` or `production`

2. **"Invalid APNs authentication key"**
   - Verify the `.p8` file is uploaded correctly
   - Check Key ID and Team ID match

3. **"FCM token not received"**
   - Check FirebaseSetup.swift implementation
   - Verify notification permissions are granted
   - Check network connectivity

4. **"Notifications not showing"**
   - Check notification permissions
   - Verify UNUserNotificationCenterDelegate implementation
   - Test with different app states (foreground, background, terminated)

#### **Debug Commands**
```bash
# Check Firebase project configuration
firebase projects:list

# Test FCM connection
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"to":"TEST_TOKEN","notification":{"title":"Test"}}'
```

### **8. Security Considerations**

#### **FCM Token Security**
- Store FCM tokens securely in your database
- Validate tokens before sending notifications
- Implement token refresh logic

#### **APNs Security**
- Keep `.p8` files secure
- Use different keys for development and production
- Rotate keys periodically

### **9. Monitoring**

#### **Firebase Console**
- Monitor FCM delivery rates
- Check for failed deliveries
- Review analytics

#### **AWS CloudWatch**
- Monitor FCM API calls
- Track notification success rates
- Set up alerts for failures

## ✅ **Complete Setup Checklist**

- [ ] **Firebase Console**: Cloud Messaging enabled
- [ ] **iOS App**: Updated FirebaseSetup.swift with FCM
- [ ] **APNs**: Authentication key uploaded to Firebase
- [ ] **Service Account**: JSON uploaded to AWS Secrets Manager
- [ ] **Permissions**: Notification permissions granted
- [ ] **Testing**: FCM tokens being generated and sent to backend
- [ ] **Production**: APNs production certificates configured

Once all these steps are completed, your FCM push notifications will work properly! 🚀 
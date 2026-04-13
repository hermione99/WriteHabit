# Push Notifications Setup Guide

## Overview
Push notifications are now set up for:
- ❤️ **Likes** on your essays
- 💬 **Comments** on your essays  
- 👋 **Friend requests**

## Prerequisites
1. Firebase project with Blaze plan (pay-as-you-go)
2. Firebase CLI installed: `npm install -g firebase-tools`
3. Node.js 18+ installed

## Setup Steps

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### 2. Initialize Cloud Functions
```bash
cd /Users/leia/.openclaw/workspace/DailyWrite/cloud-functions
firebase init functions
```
- Select your Firebase project
- Choose JavaScript
- Say "Yes" to installing dependencies

### 3. Deploy Functions
```bash
firebase deploy --only functions
```

This will deploy:
- `onLikeCreated` - Sends notification when someone likes your essay
- `onCommentCreated` - Sends notification when someone comments
- `onFriendRequestCreated` - Sends notification for friend requests

### 4. Update Xcode Project

#### Add Firebase Messaging to Package Dependencies:
1. In Xcode: **File → Add Packages**
2. Add: `https://github.com/firebase/firebase-ios-sdk`
3. Select **FirebaseMessaging**

#### Update Info.plist
Add to `Info.plist`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

#### Add Push Notification Capability:
1. Select your target
2. **Signing & Capabilities** → **+ Capability**
3. Add **Push Notifications**
4. Add **Background Modes** → Check **Remote notifications**

### 5. Test Notifications
1. Run app on physical device (simulator doesn't support push)
2. Write an essay
3. Have a friend (on another device) like/comment on it
4. You should receive a push notification!

## Troubleshooting

### Not receiving notifications?
- Check Firebase Console → Functions → Logs for errors
- Verify FCM token is saved in Firestore (users/{userId}/fcmToken)
- Check device Settings → Notifications → DailyWrite
- Ensure app is in background (foreground notifications work but less visible)

### Function deployment fails?
```bash
# Check logs
firebase functions:log

# Redeploy
firebase deploy --only functions --debug
```

## Cost Considerations
Firebase Cloud Functions have a generous free tier:
- 2 million invocations/month free
- Usually covers small-medium apps completely

Monitor usage in Firebase Console → Usage

## Files Changed
- `cloud-functions/index.js` - Cloud Functions
- `cloud-functions/package.json` - Dependencies
- `Services/NotificationService.swift` - FCM token handling
- `DailyWriteApp.swift` - Remote notification registration

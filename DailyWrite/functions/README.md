# DailyWrite Cloud Functions

This directory contains Firebase Cloud Functions for sending push notifications.

## Setup

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Navigate to functions directory**:
   ```bash
   cd DailyWrite/functions
   ```

4. **Install dependencies**:
   ```bash
   npm install
   ```

5. **Deploy functions**:
   ```bash
   firebase deploy --only functions
   ```

## Functions

### `sendPushNotification`
Triggered when a document is created in the `notifications` collection. Sends FCM push notification to the recipient's device.

### `notifyOnComment`
Triggered when a new comment is added. Creates a notification for the essay author (or parent comment author for replies).

### `notifyOnLike`
Triggered when a new like is added. Creates a notification for the essay author.

## Environment Variables

Make sure your Firebase project has the Blaze plan (pay-as-you-go) for external API calls.

## Testing

Test locally with Firebase emulator:
```bash
firebase emulators:start --only functions
```

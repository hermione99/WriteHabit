const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Send notification when someone likes an essay
exports.onLikeCreated = functions.firestore
  .document('likes/{likeId}')
  .onCreate(async (snap, context) => {
    const like = snap.data();
    const { essayId, userId } = like;
    
    // Get the essay
    const essayDoc = await admin.firestore().doc(`essays/${essayId}`).get();
    if (!essayDoc.exists) return;
    
    const essay = essayDoc.data();
    const authorId = essay.authorId;
    
    // Don't notify if user liked their own essay
    if (authorId === userId) return;
    
    // Get the liker's profile
    const likerDoc = await admin.firestore().doc(`users/${userId}`).get();
    const likerName = likerDoc.exists ? likerDoc.data().displayName : 'Someone';
    
    // Get author's FCM token
    const authorDoc = await admin.firestore().doc(`users/${authorId}`).get();
    if (!authorDoc.exists) return;
    
    const fcmToken = authorDoc.data().fcmToken;
    if (!fcmToken) return;
    
    // Send notification
    const message = {
      token: fcmToken,
      notification: {
        title: 'New Like! ❤️',
        body: `${likerName} liked your essay "${essay.title || 'Untitled'}"`,
      },
      data: {
        type: 'like',
        essayId: essayId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default',
          },
        },
      },
    };
    
    try {
      await admin.messaging().send(message);
      console.log('Like notification sent successfully');
    } catch (error) {
      console.error('Error sending like notification:', error);
    }
  });

// Send notification when someone comments on an essay
exports.onCommentCreated = functions.firestore
  .document('comments/{commentId}')
  .onCreate(async (snap, context) => {
    const comment = snap.data();
    const { essayId, authorId: commenterId, authorName } = comment;
    
    // Get the essay
    const essayDoc = await admin.firestore().doc(`essays/${essayId}`).get();
    if (!essayDoc.exists) return;
    
    const essay = essayDoc.data();
    const authorId = essay.authorId;
    
    // Don't notify if author commented on their own essay
    if (authorId === commenterId) return;
    
    // Get author's FCM token
    const authorDoc = await admin.firestore().doc(`users/${authorId}`).get();
    if (!authorDoc.exists) return;
    
    const fcmToken = authorDoc.data().fcmToken;
    if (!fcmToken) return;
    
    // Truncate comment content for notification
    const commentPreview = comment.content.length > 50 
      ? comment.content.substring(0, 50) + '...' 
      : comment.content;
    
    // Send notification
    const message = {
      token: fcmToken,
      notification: {
        title: 'New Comment! 💬',
        body: `${authorName}: "${commentPreview}"`,
      },
      data: {
        type: 'comment',
        essayId: essayId,
        commentId: context.params.commentId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default',
          },
        },
      },
    };
    
    try {
      await admin.messaging().send(message);
      console.log('Comment notification sent successfully');
    } catch (error) {
      console.error('Error sending comment notification:', error);
    }
  });

// Send notification for friend requests
exports.onFriendRequestCreated = functions.firestore
  .document('friendRequests/{requestId}')
  .onCreate(async (snap, context) => {
    const request = snap.data();
    const { toUserId, fromUserId } = request;
    
    // Get sender's profile
    const senderDoc = await admin.firestore().doc(`users/${fromUserId}`).get();
    if (!senderDoc.exists) return;
    
    const senderName = senderDoc.data().displayName;
    
    // Get receiver's FCM token
    const receiverDoc = await admin.firestore().doc(`users/${toUserId}`).get();
    if (!receiverDoc.exists) return;
    
    const fcmToken = receiverDoc.data().fcmToken;
    if (!fcmToken) return;
    
    // Send notification
    const message = {
      token: fcmToken,
      notification: {
        title: 'Friend Request! 👋',
        body: `${senderName} wants to be your friend`,
      },
      data: {
        type: 'friendRequest',
        requestId: context.params.requestId,
        fromUserId: fromUserId,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      apns: {
        payload: {
          aps: {
            badge: 1,
            sound: 'default',
          },
        },
      },
    };
    
    try {
      await admin.messaging().send(message);
      console.log('Friend request notification sent successfully');
    } catch (error) {
      console.error('Error sending friend request notification:', error);
    }
  });

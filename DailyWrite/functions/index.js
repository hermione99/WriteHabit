const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const functions = require("firebase-functions");

// Initialize Firebase Admin
initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Triggered when a new notification is created in Firestore
 * Sends FCM push notification to the recipient
 */
exports.sendPushNotification = functions.firestore
    .document("notifications/{notificationId}")
    .onCreate(async (snap, context) => {
      const notification = snap.data();
      const {userId, title, body, type} = notification;

      console.log(`New notification for user ${userId}: ${title}`);

      try {
        // Get user's FCM token
        const userDoc = await db.collection("users").doc(userId).get();
        const fcmToken = userDoc.data()?.fcmToken;

        if (!fcmToken) {
          console.log(`No FCM token for user ${userId}`);
          return null;
        }

        // Prepare notification payload
        const payload = {
          token: fcmToken,
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: type || "general",
            notificationId: context.params.notificationId,
            relatedId: notification.relatedId || "",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          apns: {
            payload: {
              aps: {
                badge: 1,
                sound: "default",
              },
            },
          },
        };

        // Send the message
        const response = await messaging.send(payload);
        console.log(`Push notification sent: ${response}`);

        // Update the notification document with sent status
        await snap.ref.update({
          pushSent: true,
          pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return response;
      } catch (error) {
        console.error("Error sending push notification:", error);
        
        // Update notification with error
        await snap.ref.update({
          pushSent: false,
          pushError: error.message,
        });
        
        return null;
      }
    });

/**
 * Triggered when a new comment is added
 * Sends notification to essay author
 */
exports.notifyOnComment = functions.firestore
    .document("comments/{commentId}")
    .onCreate(async (snap, context) => {
      const comment = snap.data();
      const {essayId, authorId, authorName, content, parentCommentId} = comment;

      try {
        // Get essay details
        const essayDoc = await db.collection("essays").doc(essayId).get();
        const essay = essayDoc.data();

        if (!essay) {
          console.log(`Essay ${essayId} not found`);
          return null;
        }

        // Don't notify if commenting on own essay/reply
        if (authorId === essay.authorId && !parentCommentId) {
          console.log("User commented on own essay, skipping notification");
          return null;
        }

        let recipientId;
        let title;
        let body;

        if (parentCommentId) {
          // It's a reply - notify parent comment author
          const parentComment = await db.collection("comments")
              .doc(parentCommentId).get();
          const parentData = parentComment.data();
          
          if (!parentData || parentData.authorId === authorId) {
            console.log("Parent comment not found or self-reply");
            return null;
          }
          
          recipientId = parentData.authorId;
          title = "New Reply";
          body = `${authorName} replied to your comment: ${content.substring(0, 50)}${content.length > 50 ? "..." : ""}`;
        } else {
          // It's a top-level comment - notify essay author
          recipientId = essay.authorId;
          title = "New Comment";
          body = `${authorName} commented on your essay: ${content.substring(0, 50)}${content.length > 50 ? "..." : ""}`;
        }

        // Create in-app notification
        await db.collection("notifications").add({
          userId: recipientId,
          type: parentCommentId ? "reply" : "comment",
          title: title,
          body: body,
          relatedId: essayId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Notification created for user ${recipientId}`);
        return null;
      } catch (error) {
        console.error("Error in notifyOnComment:", error);
        return null;
      }
    });

/**
 * Triggered when a like is added to an essay
 * Sends notification to essay author
 */
exports.notifyOnLike = functions.firestore
    .document("likes/{likeId}")
    .onCreate(async (snap, context) => {
      const like = snap.data();
      const {essayId, userId} = like;

      try {
        // Get essay details
        const essayDoc = await db.collection("essays").doc(essayId).get();
        const essay = essayDoc.data();

        if (!essay) {
          console.log(`Essay ${essayId} not found`);
          return null;
        }

        // Don't notify if liking own essay
        if (userId === essay.authorId) {
          console.log("User liked own essay, skipping notification");
          return null;
        }

        // Get liker's name
        const userDoc = await db.collection("users").doc(userId).get();
        const user = userDoc.data();
        const likerName = user?.username || user?.displayName || "Someone";

        // Create notification
        await db.collection("notifications").add({
          userId: essay.authorId,
          type: "like",
          title: "New Like",
          body: `${likerName} liked your essay`,
          relatedId: essayId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Like notification created for user ${essay.authorId}`);
        return null;
      } catch (error) {
        console.error("Error in notifyOnLike:", error);
        return null;
      }
    });

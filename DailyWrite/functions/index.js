const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
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
    .document("pushNotifications/{notificationId}")
    .onCreate(async (snap, context) => {
      const data = snap.data();
      const {token, title, body, userId} = data;

      console.log(`New push notification for user ${userId}`);

      try {
        if (!token) {
          console.log(`No FCM token provided`);
          return null;
        }

        // Prepare notification payload
        const payload = {
          token: token,
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: data.type || "general",
            notificationId: context.params.notificationId,
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

        // Update the document with sent status
        await snap.ref.update({
          sent: true,
          sentAt: FieldValue.serverTimestamp(),
        });

        return response;
      } catch (error) {
        console.error("Error sending push notification:", error);
        
        // Update with error
        await snap.ref.update({
          sent: false,
          error: error.message,
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
          createdAt: FieldValue.serverTimestamp(),
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

/**
 * Triggered when an essay is created
 * Updates keyword stats
 */
exports.updateKeywordStatsOnCreate = functions.firestore
    .document("essays/{essayId}")
    .onCreate(async (snap, context) => {
      const essay = snap.data();
      const {keyword, isDraft, deletedAt} = essay;

      // Only count non-draft, non-deleted essays
      if (isDraft || deletedAt) {
        return null;
      }

      try {
        const keywordRef = db.collection("keywordStats").doc(keyword);
        await keywordRef.set({
          keyword: keyword,
          essayCount: FieldValue.increment(1),
          lastUpdated: FieldValue.serverTimestamp(),
        }, {merge: true});
        
        console.log(`Keyword stats updated for "${keyword}" (+1)`);
        return null;
      } catch (error) {
        console.error("Error updating keyword stats on create:", error);
        return null;
      }
    });

/**
 * Triggered when an essay is updated (e.g., deleted)
 * Updates keyword stats
 */
exports.updateKeywordStatsOnUpdate = functions.firestore
    .document("essays/{essayId}")
    .onUpdate(async (change, context) => {
      const newData = change.after.data();
      const oldData = change.before.data();

      // Check if essay was deleted or marked as draft
      const wasActive = !oldData.isDraft && !oldData.deletedAt;
      const isActive = !newData.isDraft && !newData.deletedAt;

      if (wasActive === isActive) {
        return null; // No change in active status
      }

      const keyword = newData.keyword || oldData.keyword;
      if (!keyword) return null;

      try {
        const keywordRef = db.collection("keywordStats").doc(keyword);
        
        if (isActive && !wasActive) {
          // Essay became active
          await keywordRef.set({
            keyword: keyword,
            essayCount: FieldValue.increment(1),
            lastUpdated: FieldValue.serverTimestamp(),
          }, {merge: true});
          console.log(`Keyword stats updated for "${keyword}" (+1)`);
        } else if (!isActive && wasActive) {
          // Essay became inactive (deleted or draft)
          await keywordRef.set({
            keyword: keyword,
            essayCount: FieldValue.increment(-1),
            lastUpdated: FieldValue.serverTimestamp(),
          }, {merge: true});
          console.log(`Keyword stats updated for "${keyword}" (-1)`);
        }
        
        return null;
      } catch (error) {
        console.error("Error updating keyword stats on update:", error);
        return null;
      }
    });

/**
 * HTTP endpoint to recalculate all keyword stats
 * Call this once to initialize the stats
 */
exports.recalculateKeywordStats = functions.https.onRequest(async (req, res) => {
  try {
    // Get all active essays
    const essaysSnapshot = await db.collection("essays")
        .where("isDraft", "==", false)
        .get();

    // Count by keyword
    const counts = {};
    essaysSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const keyword = data.keyword;
      if (keyword) {
        counts[keyword] = (counts[keyword] || 0) + 1;
      }
    });

    // Save to keywordStats collection
    const batch = db.batch();
    for (const [keyword, count] of Object.entries(counts)) {
      const ref = db.collection("keywordStats").doc(keyword);
      batch.set(ref, {
        keyword: keyword,
        essayCount: count,
        lastUpdated: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    res.json({
      success: true,
      message: `Updated ${Object.keys(counts).length} keywords`,
      counts: counts,
    });
  } catch (error) {
    console.error("Error recalculating keyword stats:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

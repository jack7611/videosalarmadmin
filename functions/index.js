const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");
const axios = require("axios");

// Make sure to set these in your Firebase Functions config:
// firebase functions:config:set razorpay.key_id="YOUR_KEY_ID" razorpay.key_secret="YOUR_KEY_SECRET"
const RAZORPAY_KEY_ID = functions.config().razorpay.key_id;
const RAZORPAY_KEY_SECRET = functions.config().razorpay.key_secret;

admin.initializeApp();
exports.schedulePaymentVerification = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const userId = context.params.userId;

    // Check if PurchaseToken was just added or updated
    const purchaseTokenChanged =
      afterData.PurchaseToken &&
      afterData.PurchaseToken !== beforeData.PurchaseToken &&
      afterData.paymentMethod === "razorpay";

    if (!purchaseTokenChanged) {
      return null;
    }

    console.log(
      `New Razorpay payment detected for user ${userId}. Payment ID: ${afterData.PurchaseToken}`
    );

    // CRITICAL SAFETY CHECK: Only verify if this is a brand new payment (updatedAt is recent)
    // This prevents re-verification of old payments when function is first deployed
    const updatedAt = afterData.updatedAt;
    if (updatedAt) {
      const updateTime = updatedAt.toDate();
      const now = new Date();
      const timeDiffMinutes = (now - updateTime) / (1000 * 60);

      // Only process if updated within last 5 minutes (brand new payment)
      if (timeDiffMinutes > 5) {
        console.log(
          `Payment for user ${userId} is older than 5 minutes. Skipping verification to avoid affecting existing payments.`
        );
        return null;
      }
    }

    // Check if already has BackendPaymentStatus to avoid re-verification
    if (
      afterData.BackendPaymentStatus === "active" ||
      afterData.BackendPaymentStatus === "verified"
    ) {
      console.log(`Payment already verified for user ${userId}. Skipping.`);
      return null;
    }

    // Schedule verification task for 1 minute later
    const scheduledTime = admin.firestore.Timestamp.fromMillis(
      Date.now() + 60000 // 1 minute from now
    );

    try {
      await admin
        .firestore()
        .collection("payment_verification_queue")
        .add({
          userId: userId,
          razorpayPaymentId: afterData.PurchaseToken,
          razorpayOrderId: afterData.OrderId || "",
          planId: afterData.PlanId || "",
          subscriptionType: afterData.SubscriptionType || "",
          scheduledTime: scheduledTime,
          status: "pending",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log(`Payment verification scheduled for user ${userId}`);
      return null;
    } catch (error) {
      console.error("Error scheduling payment verification:", error);
      return null;
    }
  });

exports.verifyScheduledPayments = functions.pubsub
  .schedule("every 1 minutes")
  .onRun(async (context) => {
    console.log("Running scheduled payment verification check...");

    const now = admin.firestore.Timestamp.now();
    const queueRef = admin.firestore().collection("payment_verification_queue");

    try {
      const snapshot = await queueRef
        .where("status", "==", "pending")
        .where("scheduledTime", "<=", now)
        .limit(100)
        .get();

      if (snapshot.empty) {
        console.log("No pending payments to verify.");
        return null;
      }

      console.log(`Found ${snapshot.size} payments to verify.`);

      const verificationPromises = snapshot.docs.map((doc) =>
        verifyPayment(doc.id, doc.data())
      );

      await Promise.allSettled(verificationPromises);

      console.log("Completed payment verification batch.");
      return null;
    } catch (error) {
      console.error("Error in scheduled payment verification:", error);
      return null;
    }
  });

async function verifyPayment(queueDocId, queueData) {
  const { userId, razorpayPaymentId, razorpayOrderId } = queueData;

  console.log(
    `Verifying payment for user: ${userId}, Payment ID: ${razorpayPaymentId}`
  );

  try {
    // Fetch payment details from Razorpay API
    const paymentDetails = await fetchRazorpayPaymentDetails(razorpayPaymentId);

    console.log(`Payment status from Razorpay: ${paymentDetails.status}`);

    if (
      paymentDetails.status === "captured" ||
      paymentDetails.status === "authorized"
    ) {
      console.log(`Payment ${razorpayPaymentId} was successful!`);
      await handleSuccessfulPayment(userId, queueDocId, paymentDetails);
    } else if (paymentDetails.status === "failed") {
      console.log(`Payment ${razorpayPaymentId} failed.`);
      await handleFailedPayment(userId, queueDocId, paymentDetails);
    } else {
      console.log(
        `Payment ${razorpayPaymentId} is in ${paymentDetails.status} state. Will retry.`
      );
      await markQueueItemForRetry(queueDocId);
    }
  } catch (error) {
    console.error(`Error verifying payment ${razorpayPaymentId}:`, error);
    await markQueueItemAsError(queueDocId, error.message);
  }
}

async function fetchRazorpayPaymentDetails(razorpayPaymentId) {
  const url = `https://api.razorpay.com/v1/payments/${razorpayPaymentId}`;
  const auth = Buffer.from(
    `${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`
  ).toString("base64");

  try {
    const response = await axios.get(url, {
      headers: {
        Authorization: `Basic ${auth}`,
      },
    });

    return response.data;
  } catch (error) {
    console.error(
      "Error fetching payment details from Razorpay:",
      error.response?.data || error.message
    );
    throw new Error("Failed to fetch payment details from Razorpay");
  }
}

async function handleSuccessfulPayment(userId, queueDocId, paymentDetails) {
  const batch = admin.firestore().batch();

  // Update user's BackendPaymentStatus
  const userRef = admin.firestore().collection("users").doc(userId);
  batch.update(userRef, {
    BackendPaymentStatus: "active",
    BackendVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    BackendVerifiedAmount: paymentDetails.amount / 100, // Convert from paise to rupees
    BackendRazorpayStatus: paymentDetails.status,
  });

  // Mark queue item as completed
  const queueRef = admin
    .firestore()
    .collection("payment_verification_queue")
    .doc(queueDocId);
  batch.update(queueRef, {
    status: "completed",
    result: "success",
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    razorpayStatus: paymentDetails.status,
  });

  await batch.commit();

  console.log(`Successfully verified payment for user ${userId}`);

  // Send success notification
  await sendPaymentNotification(
    userId,
    "Payment Successful! 🎉",
    "Thank you for purchasing VideoAlarm subscription! Enjoy exclusive content and premium features.",
    "success"
  );
}

async function handleFailedPayment(userId, queueDocId, paymentDetails) {
  const batch = admin.firestore().batch();

  // Update user document with failed status
  const userRef = admin.firestore().collection("users").doc(userId);
  batch.update(userRef, {
    BackendPaymentStatus: "failed",
    BackendVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    BackendRazorpayStatus: paymentDetails.status,
    BackendFailureReason: paymentDetails.error_description || "Payment failed",
  });

  // Mark queue item as completed
  const queueRef = admin
    .firestore()
    .collection("payment_verification_queue")
    .doc(queueDocId);
  batch.update(queueRef, {
    status: "completed",
    result: "failed",
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    razorpayStatus: paymentDetails.status,
    failureReason: paymentDetails.error_description || "Payment failed",
  });

  await batch.commit();

  console.log(`Payment marked as failed for user ${userId}`);

  // Send failure notification
  await sendPaymentNotification(
    userId,
    "Payment Failed ❌",
    "Your payment could not be processed. Please try again or contact support if the amount was deducted.",
    "failed"
  );
}

async function markQueueItemForRetry(queueDocId) {
  try {
    await admin
      .firestore()
      .collection("payment_verification_queue")
      .doc(queueDocId)
      .update({
        retryCount: admin.firestore.FieldValue.increment(1),
        lastRetryAt: admin.firestore.FieldValue.serverTimestamp(),
      });
  } catch (error) {
    console.error("Error marking queue item for retry:", error);
  }
}

async function markQueueItemAsError(queueDocId, errorMessage) {
  try {
    await admin
      .firestore()
      .collection("payment_verification_queue")
      .doc(queueDocId)
      .update({
        status: "error",
        errorMessage: errorMessage,
        errorAt: admin.firestore.FieldValue.serverTimestamp(),
      });
  } catch (error) {
    console.error("Error updating queue item:", error);
  }
}

async function sendPaymentNotification(userId, title, body, type) {
  try {
    const userRef = admin.firestore().collection("users").doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      console.error(`User document for user ID ${userId} not found.`);
      return;
    }

    const userData = userDoc.data();
    const fcmTokens = userData.fcmTokens;

    if (!fcmTokens || !Array.isArray(fcmTokens) || fcmTokens.length === 0) {
      console.log(`User ${userId} has no registered FCM tokens.`);
      return;
    }

    console.log(`Sending ${type} notification to ${fcmTokens.length} tokens.`);

    const sendPromises = fcmTokens.map((token) => {
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          type: type,
          screen: "subscription_screen",
        },
        token: token,
      };
      return admin.messaging().send(message);
    });

    const results = await Promise.allSettled(sendPromises);

    // Cleanup invalid tokens
    const tokensToRemove = [];
    results.forEach((result, index) => {
      const token = fcmTokens[index];
      if (result.status === "fulfilled") {
        console.log(
          `Successfully sent notification to token ending in ...${token.slice(
            -6
          )}.`
        );
      } else {
        const error = result.reason;
        console.error(
          `Failed to send to token ending in ...${token.slice(-6)}.`
        );
        if (
          error.code === "messaging/invalid-registration-token" ||
          error.code === "messaging/registration-token-not-registered"
        ) {
          tokensToRemove.push(token);
        }
      }
    });

    if (tokensToRemove.length > 0) {
      await userRef.update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
      });
      console.log("Removed invalid tokens.");
    }
  } catch (error) {
    console.error("Error sending payment notification:", error);
  }
}
exports.notifyUserOnAdminReply = functions.firestore
  .document("tickets/{ticketId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const ticketId = context.params.ticketId;

    if (messageData.senderRole !== "admin") {
      console.log("Message not from admin. No notification sent.");
      return null;
    }

    console.log(
      `Admin replied to ticket: ${ticketId}. Preparing notification.`
    );

    try {
      const ticketRef = admin.firestore().collection("tickets").doc(ticketId);
      const ticketDoc = await ticketRef.get();

      if (!ticketDoc.exists) {
        console.error(`Ticket document ${ticketId} not found.`);
        return null;
      }

      const ticketData = ticketDoc.data();
      const userId = ticketData.userId;

      if (!userId) {
        console.error(`Ticket ${ticketId} is missing the 'userId' field.`);
        return null;
      }

      const userRef = admin.firestore().collection("users").doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        console.error(`User document for user ID ${userId} not found.`);
        return null;
      }

      const userData = userDoc.data();
      const fcmTokens = userData.fcmTokens;

      if (!fcmTokens || !Array.isArray(fcmTokens) || fcmTokens.length === 0) {
        console.log(`User ${userId} has no registered FCM tokens.`);
        return null;
      }

      const messageText = messageData.text || "An admin sent you an image.";
      const subject = ticketData.category || "your ticket";

      console.log(
        `Preparing to send notifications to ${fcmTokens.length} tokens.`
      );

      const sendPromises = fcmTokens.map((token) => {
        const message = {
          notification: {
            title: `New Reply on: "${subject}"`,
            body: messageText,
          },
          data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            ticketId: ticketId,
            screen: "chat_screen",
          },
          token: token,
        };
        return admin.messaging().send(message);
      });

      const results = await Promise.allSettled(sendPromises);

      await cleanupInvalidTokens(results, fcmTokens, userRef);

      console.log("All notification operations complete.");
      return null;
    } catch (error) {
      console.error(
        "A critical error occurred in the main function body:",
        error
      );
      return null;
    }
  });

async function cleanupInvalidTokens(results, tokens, userRef) {
  const tokensToRemove = [];

  results.forEach((result, index) => {
    const token = tokens[index];

    if (result.status === "fulfilled") {
      console.log(
        `Successfully sent notification to token ending in ...${token.slice(
          -6
        )}.`
      );
    } else {
      const error = result.reason;
      console.error(`Failed to send to token ending in ...${token.slice(-6)}.`);
      console.error(`Error Code: ${error.code}`);
      console.error(`Error Message: ${error.message}`);

      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        console.log(`Scheduling token ...${token.slice(-6)} for removal.`);
        tokensToRemove.push(token);
      }
    }
  });

  if (tokensToRemove.length > 0) {
    console.log(
      `Removing ${tokensToRemove.length} invalid tokens from user document.`
    );
    try {
      await userRef.update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
      });
      console.log("Successfully removed invalid tokens.");
    } catch (updateError) {
      console.error("Error trying to remove invalid tokens:", updateError);
    }
  }
}

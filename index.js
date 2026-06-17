// Import required libraries
const express = require("express");
const admin = require("firebase-admin");
const axios = require("axios");
const path = require("path");
const fs = require("fs");

// Load your Firebase service account credentials
let serviceAccount;
try {
  serviceAccount = require("./serviceAccountKey.json");
} catch (error) {
  console.error("Error loading service account key:", error.message);
  console.error(
    "Please make sure serviceAccountKey.json exists and is valid JSON"
  );
  process.exit(1);
}

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Firestore DB instance
const db = admin.firestore();

// Initialize Express app
const app = express();

// Configure Express middleware
app.use(
  express.json({
    limit: "50mb",
    verify: (req, res, buf) => {
      try {
        // Validate JSON format to catch parsing errors early
        if (buf.length > 0) {
          JSON.parse(buf.toString());
        }
      } catch (e) {
        console.error("⚠️ Invalid JSON received:", e.message);
        throw new Error("Invalid JSON format");
      }
    },
  })
);

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, "uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Function to generate a 6-digit OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Helper function to format phone number to E.164 format
function formatPhoneNumber(phone) {
  if (!phone) return null;

  // If phone already has + prefix, return as is
  if (phone.startsWith("+")) {
    return phone;
  }

  // For Indian phone numbers, add +91 prefix if number is 10 digits
  if (phone.length === 10) {
    return `+91${phone}`;
  }

  // For numbers that might already have country code without +
  if (phone.startsWith("91") && phone.length === 12) {
    return `+${phone}`;
  }

  // Default fallback - add + prefix
  return `+${phone}`;
}

// CORS — allow requests from the admin web app
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  next();
});

// Error handling middleware
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && "body" in err) {
    console.error("JSON Parse Error:", err.message);
    return res.status(400).json({ message: "Invalid JSON payload" });
  }
  next(err);
});

// API endpoint to check if user exists
app.post("/checkUserExists", async (req, res) => {
  const { phone } = req.body;

  // Check if phone number is provided
  if (!phone) {
    console.log("🚫 /checkUserExists: Phone number is required");
    return res.status(400).json({ message: "Phone number is required" });
  }

  console.log(`🔍 Checking user existence for phone: ${phone}`);

  const formattedPhone = formatPhoneNumber(phone);

  try {
    // First check in Firebase Auth
    try {
      const userRecord = await admin
        .auth()
        .getUserByPhoneNumber(formattedPhone);
      console.log(
        `✅ /checkUserExists: User with phone ${formattedPhone} exists in Firebase Auth`
      );
      return res.status(200).json({ exists: true });
    } catch (authError) {
      if (authError.code === "auth/user-not-found") {
        // Fall back to checking Firestore if not found in Auth
        const usersRef = db.collection("users");
        const snapshot = await usersRef
          .where("phone", "==", phone)
          .limit(1)
          .get();

        if (snapshot.empty) {
          console.log(
            `❌ /checkUserExists: User with phone ${phone} does not exist`
          );
          return res.status(200).json({ exists: false });
        } else {
          console.log(
            `✅ /checkUserExists: User with phone ${phone} exists in Firestore`
          );
          return res.status(200).json({ exists: true });
        }
      } else {
        throw authError; // Re-throw unexpected auth errors
      }
    }
  } catch (error) {
    console.error("❌ /checkUserExists: Error checking user existence:", error);
    return res
      .status(500)
      .json({ message: "Internal server error during user check" });
  }
});

// API endpoint to send OTP
app.post("/sendOtp", async (req, res) => {
  const { phone } = req.body;

  // Check if phone number is provided
  if (!phone) {
    console.log("🚫 /sendOtp: Phone number is required");
    return res.status(400).json({ message: "Phone number is required" });
  }

  //  Demo number for static otp
  const demoNumber = "9112597757";
  let otp = generateOTP();

  if (phone === demoNumber) {
    otp = "123456";
  }

  try {
    // Save OTP to Firestore along with a timestamp
    await db.collection("otp_requests").doc(phone).set({
      otp,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Construct the SMS URL
    const smsMessage = `Dear User, your OTP is ${otp}. Do not share it with anyone. Valid for 5 minutes. -Team Videos Alarm`;
    const smsUrl = `https://smpp1.sms24hours.com/SMSApi/send?userid=ccfeltd&password=Eq5Q79b6&sendMethod=quick&mobile=${phone}&msg=${encodeURIComponent(
      smsMessage
    )}&senderid=VALARM&msgType=text&dltEntityId=1401613590000051630&dltTemplateId=1407174401860143284&duplicatecheck=true&output=json`;

    console.log(`📤 Sending OTP for phone: ${phone} with OTP: ${otp}`);

    // Send the SMS via your provider
    const response = await axios.get(smsUrl);
    console.log("✅ OTP sent response:", response.data);
    res.status(200).json({ message: "OTP sent" });
  } catch (err) {
    console.error("❌ Failed to send OTP:", err.message);
    res.status(500).json({ message: "Failed to send OTP", error: err.message });
  }
});

// API endpoint to verify OTP
app.post("/verifyOtp", async (req, res) => {
  console.log("➡️ Received /verifyOtp request");
  const { phone, otp } = req.body;

  if (!phone || !otp) {
    console.log("🚫 /verifyOtp: Phone and OTP are required");
    return res.status(400).json({ message: "Phone and OTP are required" });
  }

  console.log(`🔑 Verifying OTP ${otp} for phone: ${phone}`);

  try {
    // Verify OTP
    const docRef = db.collection("otp_requests").doc(phone);
    const doc = await docRef.get();

    if (!doc.exists) {
      console.log(`❌ /verifyOtp: OTP not found for phone: ${phone}`);
      return res.status(400).json({ message: "OTP not found or already used" });
    }

    const data = doc.data();
    if (!data?.createdAt) {
      console.log(
        `❌ /verifyOtp: Invalid OTP timestamp data for phone: ${phone}`
      );
      return res.status(400).json({ message: "Invalid OTP data" });
    }

    const now = new Date();
    const createdAt = data.createdAt.toDate();
    const timeDiff = (now - createdAt) / 1000; // Time difference in seconds

    // Demo number OTP verification
    const demoNumber = "9112597757";
    let isOtpValid = data.otp === otp;
    if (phone === demoNumber) {
      isOtpValid = otp === "123456";
    }

    if (!isOtpValid) {
      console.log(
        `❌ /verifyOtp: Invalid OTP provided ${otp} for phone: ${phone}`
      );
      return res.status(400).json({ message: "Invalid OTP" });
    }

    if (timeDiff > 300) {
      // 300 seconds = 5 minutes
      console.log(`❌ /verifyOtp: OTP expired for phone: ${phone}`);
      await docRef.delete(); // Clean up expired OTP
      return res.status(400).json({ message: "OTP expired" });
    }

    // Format phone number in E.164 format (required by Firebase)
    const formattedPhone = formatPhoneNumber(phone);
    console.log(`📞 Formatted phone number: ${formattedPhone}`);

    // Handle Firebase Authentication
    let userRecord;
    try {
      // Try to find existing user by phone number
      userRecord = await admin.auth().getUserByPhoneNumber(formattedPhone);
      console.log(
        `👤 User with phone ${formattedPhone} exists in Firebase Auth`
      );
    } catch (error) {
      if (error.code === "auth/user-not-found") {
        // Create a new user with the phone number as authentication method
        userRecord = await admin.auth().createUser({
          phoneNumber: formattedPhone,
        });
        console.log(
          `➕ Created new user with phone ${formattedPhone} in Firebase Auth (UID: ${userRecord.uid})`
        );

        // Optional: Create a corresponding user document in Firestore
        await db.collection("users").doc(userRecord.uid).set({
          phone: phone,
          phoneFormatted: formattedPhone,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        console.error(`❌ Firebase Auth error:`, error);
        throw error; // Re-throw unexpected errors
      }
    }

    // Generate custom token using Firebase-generated UID
    const customToken = await admin.auth().createCustomToken(userRecord.uid);
    console.log(`🔑 Custom token generated for UID: ${userRecord.uid}`);

    // Clean up used OTP
    await docRef.delete();
    console.log(`🗑️ OTP deleted for phone: ${phone}`);

    // Return success response with token and UID
    res.status(200).json({
      token: customToken,
      uid: userRecord.uid,
      message: "OTP verified and token generated",
    });
  } catch (err) {
    console.error("❌ /verifyOtp: Error during OTP verification:", err);
    res.status(500).json({
      message: "Internal server error during OTP verification",
      error: err.message,
    });
  }
});

// Error handling for file deletion
app.delete("/deleteImage/:filename", (req, res) => {
  const filename = req.params.filename;
  const filepath = path.join(uploadsDir, filename);

  fs.unlink(filepath, (err) => {
    if (err) {
      console.error(`Error deleting image: ${err}`);
      // Don't fail if file doesn't exist
      if (err.code === "ENOENT") {
        return res.status(404).json({ message: "File not found" });
      }
      return res.status(500).json({ message: "Error deleting file" });
    }

    console.log(`✅ Successfully deleted file: ${filename}`);
    res.status(200).json({ message: "File deleted successfully" });
  });
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", timestamp: new Date().toISOString() });
});
// API to send new video notification
app.post("/sendNotification", async (req, res) => {
  const { title } = req.body;

  if (!title) {
    return res.status(400).json({ message: "Video title is required" });
  }

  const message = {
    notification: {
      title: "New Video Uploaded!",
      body: `${title} is now available to watch.`,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      title: "New Video Uploaded!",
      body: `${title} is now available to watch.`,
    },
    topic: "new-videos",
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("✅ Notification sent:", response);
    res.status(200).json({ message: "Notification sent successfully" });
  } catch (error) {
    console.error("❌ Failed to send notification:", error);
    res.status(500).json({ message: "Failed to send notification", error: error.message });
  }
});

// Broadcast custom notification to ALL users (festival wishes, events, announcements)
app.post("/broadcastNotification", async (req, res) => {
  const { title, body, token } = req.body;

  if (!title) {
    return res.status(400).json({ message: "title is required" });
  }

  const notificationBody = body || "";

  try {
    let response;
    if (token) {
      // Test mode: send to a specific device token only
      const message = {
        notification: { title, body: notificationBody },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          title,
          body: notificationBody,
        },
        token,
      };
      response = await admin.messaging().send(message);
      console.log("✅ Test notification sent to token:", response);
    } else {
      // Broadcast to ALL users subscribed to the 'all' topic
      const message = {
        notification: { title, body: notificationBody },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          title,
          body: notificationBody,
        },
        topic: "all",
      };
      response = await admin.messaging().send(message);
      console.log("✅ Broadcast notification sent:", response);
    }
    res.status(200).json({ message: "Notification sent successfully", response });
  } catch (error) {
    console.error("❌ Failed to send broadcast notification:", error);
    res.status(500).json({ message: "Failed to send notification", error: error.message });
  }
});
app.post("/sendNotificationtest", async (req, res) => {
  const { title } = req.body;

  if (!title) {
    return res.status(400).json({ message: "Video title is required" });
  }

  const message = {
    notification: {
      title: "New Video Uploaded!",
      body: `${title} is now available to watch.`,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK", // Important for tap-to-open
      title: "New Video Uploaded!",
      body: `${title} is now available to watch.`,
    },
    topic: "new-test", // Users must be subscribed to this topic in the app
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("✅ Notification sent:", response);
    res.status(200).json({ message: "Notification sent successfully" });
  } catch (error) {
    console.error("❌ Failed to send notification:", error);
    res.status(500).json({
      message: "Failed to send notification",
      error: error.message,
    });
  }
});
// Check if port is already in use and find an available one
function startServer(port) {
  const server = app
    .listen(port, () => {
      console.log(`✅ Server running on http://localhost:${port}`);
    })
    .on("error", (err) => {
      if (err.code === "EADDRINUSE") {
        console.warn(
          `⚠️ Port ${port} is already in use, trying ${port + 1}...`
        );
        startServer(port + 1);
      } else {
        console.error("❌ Server error:", err);
      }
    });
}

// Start the server with automatic port finding
const PORT = process.env.PORT || 3066;
startServer(PORT);

// Handle graceful shutdown
process.on("SIGTERM", () => {
  console.log("👋 SIGTERM received, shutting down gracefully");
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("👋 SIGINT received, shutting down gracefully");
  process.exit(0);
});

module.exports = app; // Export for testing

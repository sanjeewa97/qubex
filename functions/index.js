const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendChatNotification = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId = context.params.chatId;

    // Get chat details to find participants
    const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
    const chatData = chatDoc.data();
    const participants = chatData.participants;
    const senderId = message.senderId;

    // Get sender details
    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderName = senderDoc.data().name;

    // Filter out sender from recipients
    const recipientIds = participants.filter((id) => id !== senderId);

    // Get tokens for recipients
    const tokens = [];
    for (const recipientId of recipientIds) {
      const userDoc = await admin.firestore().collection("users").doc(recipientId).get();
      const userData = userDoc.data();
      if (userData && userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    }

    if (tokens.length === 0) {
      console.log("No tokens to send to.");
      return;
    }

    // Construct payload
    const payload = {
      notification: {
        title: chatData.isGroup ? chatData.groupName : senderName,
        body: message.content || (message.attachmentUrl ? "Sent an attachment" : "New message"),
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
      data: {
        chatId: chatId,
        type: "chat",
      },
    };

    // Send to devices
    await admin.messaging().sendToDevice(tokens, payload);
    console.log("Notification sent to", tokens.length, "devices.");
  });

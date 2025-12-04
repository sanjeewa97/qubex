const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.sendChatNotification = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    const chatId = event.params.chatId;

    const db = getFirestore();
    const messaging = getMessaging();

    // Get chat details to find participants
    const chatDoc = await db.collection("chats").doc(chatId).get();
    const chatData = chatDoc.data();
    const participants = chatData.participants;
    const senderId = message.senderId;

    // Get sender details
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderName = senderDoc.data().name;

    // Filter out sender from recipients
    const recipientIds = participants.filter((id) => id !== senderId);

    // Get tokens for recipients
    const tokens = [];
    for (const recipientId of recipientIds) {
      const userDoc = await db.collection("users").doc(recipientId).get();
      const userData = userDoc.data();
      if (userData && userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    }

    if (tokens.length === 0) {
      console.log("No tokens to send to.");
      return;
    }

    // Send to each device
    const notificationPromises = tokens.map((token) => {
      const payload = {
        token: token,
        notification: {
          title: chatData.isGroup ? chatData.groupName : senderName,
          body: message.content || (message.attachmentUrl ? "Sent an attachment" : "New message"),
        },
        data: {
          chatId: chatId,
          type: "chat",
        },
      };
      return messaging.send(payload);
    });

    await Promise.all(notificationPromises);
    console.log("Notification sent to", tokens.length, "devices.");
  }
);

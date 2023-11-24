/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

/* const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger"); */

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// 새로운 주문이 생성될 때 푸시 알림을 보내는 함수
exports.notifyNewOrder = functions.firestore
    .document("orders/{orderId}")
    .onCreate((snapshot, context) => {
      const orderData = snapshot.data();
      if (orderData.status === "ORDER") {
        const title = "주문 확인 중";
        const body = "매장에서 주문을 확인하고 있습니다.";
        return sendNotification(orderData, title, body);
      }
      return null;
    });

exports.notifyOrderStatusChange = functions.firestore
    .document("orders/{orderId}")
    .onUpdate((change, context) => {
      const newValue = change.after.data();
      const previousValue = change.before.data();

      // 사용자 UID와 문서의 uid 필드가 일치하는 경우에만 처리
      if (newValue.status !== previousValue.status) {
        const status = newValue.status;
        let title = "";
        let body = "";

        // 주문 상태에 따라 메시지의 제목과 본문 설정
        switch (status) {
          case "ACCEPTED":
            title = "주문 수락";
            body = "매장에서 음료를 만들고 있습니다.";
            break;
          case "READY":
            title = "주문 준비 완료";
            body = "음료가 준비되었습니다.";
            break;
          case "FINISHED":
            title = "픽업 완료";
            body = "픽업이 완료되었습니다.";
            break;
        }

        return sendNotification(newValue, title, body);
      }
      return null;
    });

function sendNotification(orderData, title, body) {
  return admin.firestore().collection("users")
      .doc(orderData.uid).get().then((doc) => {
        const user = doc.data();
        const token = user.token;

        const message = {
          notification: {
            title: title,
            body: body,
          },
          token: token,
        };

        return admin.messaging().send(message);
      }).catch((error) => {
        console.log("Error sending notification:", error);
      });
}

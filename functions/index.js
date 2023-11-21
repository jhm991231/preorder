/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.notifyOrderStatusChange = functions.firestore
    .document("orders/{orderId}")
    .onUpdate((change, context) => {
      const newValue = change.after.data();
      const previousValue = change.before.data();

      // 사용자 UID와 문서의 uid 필드가 일치하는 경우에만 처리
      if (newValue.status !== previousValue.status) {
        // Firestore에서 사용자의 FCM 토큰을 가져옵니다
        return admin.firestore().collection("users")
            .doc(newValue.uid).get().then((doc) => {
              const user = doc.data();
              const token = user.token;

              // FCM 푸시 알림 메시지 구성
              const message = {
                notification: {
                  title: "주문 상태 변경",
                  body: "주문 상태가 ${newValue.status}로 변경되었습니다.",
                  data: "주문을 준비중입니다.",
                },
                token: token,
              };

              // 푸시 알림 보내기
              return admin.messaging().send(message);
            }).catch((error) => {
              console.log("Error sending notification:", error);
            });
      }
      return null;
    });

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendOrderStatusNotification = functions.firestore
    .document('orders/{orderId}')
    .onUpdate((change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();

        if (newValue.status !== previousValue.status) {
            const message = {
                notification: {
                    title: '주문 상태 업데이트',
                    body: `주문 상태가 ${newValue.status}로 변경되었습니다.`,
                },
                token: userDeviceToken, // 사용자의 FCM 토큰
            };
            return admin.messaging().send(message);
        }
        return null;
    });

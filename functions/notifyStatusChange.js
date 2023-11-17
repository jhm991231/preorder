const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.notifyOrderStatusChange = functions.firestore
    .document('orders/{orderId}')
    .onUpdate((change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();

        // 사용자 UID와 문서의 uid 필드가 일치하는 경우에만 처리
        if (newValue.status !== previousValue.status) {
            // Firestore에서 사용자의 FCM 토큰을 가져옵니다
            return admin.firestore().collection('users').doc(newValue.uid).get().then(doc => {
                const user = doc.data();
                const token = user.token;

                // FCM 푸시 알림 메시지 구성
                const message = {
                    notification: {
                        title: '주문 상태 변경',
                        body: `주문 상태가 ${newValue.status}로 변경되었습니다.`,
                    },
                    token: token,
                };

                // 푸시 알림 보내기
                return admin.messaging().send(message);
            }).catch(error => {
                console.log('Error sending notification:', error);
            });
        }
        return null;
    });

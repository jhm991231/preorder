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

function formatDate(date) {
  const year = date.getFullYear().toString();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return year + month + day;
}

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

exports.healthUpdate = functions.pubsub.schedule('every 24 hours')
    .timeZone('Asia/Seoul').onRun(async (context) => {
      const usersSnapshot = await admin.firestore().collection('users').get();

      for (const userDoc of usersSnapshot.docs) {
        const uid = userDoc.id;
        const now =new Date();
        const dailyData = await calculateIntakeData(uid, now, 1);
        const weeklyData = await calculateIntakeData(uid, now, 7);
        const monthlyData = await calculateIntakeData(uid, now, 30);

        const userHealthRef = admin.firestore().collection('users').doc(uid).collection('health');
        await userHealthRef.doc('daily').set(dailyData, {merge: true});
        await userHealthRef.doc('weekly').set(weeklyData, {merge: true});
        await userHealthRef.doc('monthly').set(monthlyData, {merge: true});
      }

      return null;
    });

  async function calculateIntakeData(uid, date, days) {
    let totalCaffeine = 0;
    let totalCalories = 0;

    for (let i = 0; i < days; i++) {
      const dateString = formatDate(new Date(date.getFullYear(), date.getMonth(), date.getDate() - i));
      const intakeDoc = await admin.firestore().collection('users').doc(uid)
        .collection('intake').doc(dateString).get();

          if (intakeDoc.exists) {
            const data = intakeDoc.data();
            totalCaffeine += data.caffeine || 0;
            totalCalories += data.calories || 0;
          }
      }

      return {caffeine: totalCaffeine, calories: totalCalories};
    }

exports.uptateIntakeData = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    if (newValue.status === 'FINISHED' && previousValue.status !== 'FINISHED') {
      const items = newValue.items;
      let totalCaffeine = 0;
      let totalCalories = 0;

      for (const item of items) {
        if (item.isForMe) {
          const productData = await getProductData(item.productName);
          totalCaffeine += productData.caffeine * item.quantity;
          totalCalories += productData.calories * item.quantity;
        }
      }

      const dateString = formatDate(new Date());
      const intakeDocRef = admin.firestore()
        .collection('users').doc(newValue.uid)
        .collection('intake').doc(dateString);

      await intakeDocRef.set({
        caffeine: admin.firestore.FieldValue.increment(totalCaffeine),
        calories: admin.firestore.FieldValue.increment(totalCalories),
      }, {merge: true});

      const userHealthRef = admin.firestore().collection('users').doc(newValue.uid).collection('health');
      const dailyData = await calculateIntakeData(newValue.uid, new Date(), 1);
      const weeklyData = await calculateIntakeData(newValue.uid, new Date(), 7);
      const monthlyData = await calculateIntakeData(newValue.uid, new Date(), 30);

      await userHealthRef.doc('daily').set(dailyData, {merge: true});
      await userHealthRef.doc('weekly').set(weeklyData, {merge: true});
      await userHealthRef.doc('monthly').set(monthlyData, {merge: true});
    }
    return null;
  });

  async function getProductData(productName) {
    const drinksSnapshot = await admin.firestore().collectionGroup('drinks')
      .where('productName', '==', productName).get();

      if (!drinksSnapshot.empty) {
        const drinkData = drinksSnapshot.docs[0].data();
        return {
          caffeine: drinkData.caffeine || 0,
          calories: drinkData.calories || 0,
        };
      }
      return {caffeine: 0, calories: 0};
  }

  exports.calculateAverageIntake = functions.pubsub.schedule('every 24 hours').timeZone('Asia/Seoul').onRun(async (context) => {
    const usersSnapshot = await admin.firestore().collection('users').get();
    let dailyTotalCaffeine = 0;
    let dailyTotalCalories = 0;
    let weeklyTotalCaffeine = 0;
    let weeklyTotalCalories = 0;
    let monthlyTotalCaffeine = 0;
    let monthlyTotalCalories = 0;
    let userCount = 0;
    for (const userDoc of usersSnapshot.docs) {
      const healthCollection = await userDoc.ref.collection('health').get();
      console.log("Health Data for user", userDoc.id, healthCollection.docs.map((doc) => doc.data()));
      // 여기서 각 기간별로 데이터를 수집하고 합산합니다.
      healthCollection.forEach((healthDoc) => {
        const healthData = healthDoc.data();
        console.log("Health Doc Data:", healthData);
        if (healthData.daily) {
          dailyTotalCaffeine += healthData.daily.caffeine || 0;
          dailyTotalCalories += healthData.daily.calories || 0;
          console.log("Daily Health Data:", healthData);
        }
        if (healthData.weekly) {
          weeklyTotalCaffeine += healthData.weekly.caffeine || 0;
          weeklyTotalCalories += healthData.weekly.calories || 0;
        }
        if (healthData.monthly) {
          monthlyTotalCaffeine += healthData.monthly.caffeine || 0;
          monthlyTotalCalories += healthData.monthly.calories || 0;
        }
      });
      userCount++;
      console.log("User Count:", userCount);
    }
    // 평균 계산
    const averageDailyCaffeine = dailyTotalCaffeine / userCount;
    const averageDailyCalories = dailyTotalCalories / userCount;
    const averageWeeklyCaffeine = weeklyTotalCaffeine / userCount;
    const averageWeeklyCalories = weeklyTotalCalories / userCount;
    const averageMonthlyCaffeine = monthlyTotalCaffeine / userCount;
    const averageMonthlyCalories = monthlyTotalCalories / userCount;
    // Firestore에 평균 데이터 저장
    await admin.firestore().collection('healthStats').doc('average').set({
      daily: {caffeine: averageDailyCaffeine, calories: averageDailyCalories},
      weekly: {caffeine: averageWeeklyCaffeine, calories: averageWeeklyCalories},
      monthly: {caffeine: averageMonthlyCaffeine, calories: averageMonthlyCalories},
    });
    return null;
  });

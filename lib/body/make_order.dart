import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> fetchCartItems(String userId) async {
  List<Map<String, dynamic>> cartItems = [];

  try {
    var cartSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("cart")
        .get();

    for (var doc in cartSnapshot.docs) {
      cartItems.add(doc.data());
    }
  } catch (e) {
    print("Error fetching cart items: $e");
  }

  return cartItems;
}

Future<void> createOrder(String userId, List<Map<String, dynamic>> cartItems, DateTime pickupTime) async {

  var orderData = {
    'items': cartItems,
    'orderID': '생성할 orderID',  // Unique order ID 생성 방식에 따라 설정
    'pickupTime': pickupTime,
    'timestamp': FieldValue.serverTimestamp(),
    'uid': userId
  };

  await FirebaseFirestore.instance.collection("orders").add(orderData);
}

void processOrder(String userId, DateTime pickupTime) async {
  var cartItems = await fetchCartItems(userId);
  if (cartItems.isNotEmpty) {
    await createOrder(userId, cartItems, pickupTime);
    await clearCart(userId);
  }
}

Future<void> clearCart(String userId) async {
  try {
    // Firestore 인스턴스 생성
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // 장바구니 컬렉션의 경로 지정
    CollectionReference cartCollection = firestore.collection('users').doc(userId).collection('cart');

    // 장바구니 컬렉션의 모든 문서 가져오기
    QuerySnapshot cartSnapshot = await cartCollection.get();

    // 각 문서에 대해 삭제 작업 수행
    for (QueryDocumentSnapshot doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }

    print("장바구니가 비워졌습니다.");
  } catch (e) {
    print("장바구니 비우기 실패: $e");
    throw Exception("장바구니 비우기 중 에러 발생");
  }
}


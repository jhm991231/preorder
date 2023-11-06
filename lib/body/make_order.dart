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
      var data = doc.data();

      // selectedOptions가 배열이고 각각의 옵션에는 'optionName'과 'optionPrice'가 있다고 가정합니다.
      var selectedOptions = List<Map<String, dynamic>>.from(data['selectedOptions'] ?? []);

      // 새로운 구조로 상품 정보 맵 생성
      var productMap = {
        'options': selectedOptions,
        'productName': data['productName'],
        'productPrice': data['totalPrice'],
        'productId': data['productId'],
        'quantity': data['quantity']
      };

      cartItems.add(productMap);
    }
  } catch (e) {
    print("Error fetching cart items: $e");
  }

  return cartItems;
}

Future<double> calculateTotalPrice(List<Map<String, dynamic>> cartItems) async {
  double totalPrice = 0.0;

  for (var item in cartItems) {
    totalPrice += (item['productPrice'] as num?)?.toDouble() ?? 0.0;
  }

  return totalPrice;
}

Future<void> createOrder(String userId, List<Map<String, dynamic>> cartItems, DateTime pickupTime) async {

  double totalPrice = await calculateTotalPrice(cartItems);

  var orderData = {
    'items': cartItems,
    'orderID': '생성할 orderID',  // Unique order ID 생성 방식에 따라 설정
    'pickupTime': pickupTime,
    'status' : "ORDER",
    'timestamp': FieldValue.serverTimestamp(),
    'totalPrice' : totalPrice,
    'uid': userId
  };

  await FirebaseFirestore.instance.collection("orders").add(orderData);
}

Future<bool> processOrder(String userId, DateTime pickupTime) async {
  try {
    var cartItems = await fetchCartItems(userId);
    if (cartItems.isNotEmpty) {
      await createOrder(userId, cartItems, pickupTime); // 주문 생성
      await clearCart(userId); // 장바구니 비우기
      return true; // 주문 생성과 장바구니 비우기가 성공적으로 완료되었다면 true 반환
    }
    return false; // 장바구니가 비어있으면 false 반환
  } catch (e) {
    // 에러 발생 시
    print("주문 처리 중 오류 발생: $e"); // 콘솔에 에러 로그 출력
    return false; // 에러가 발생했다면 false 반환
  }
}


Future<bool> clearCart(String userId) async {
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
    return true;
  } catch (e) {
    print("장바구니 비우기 실패: $e");
    return false;
  }
}

Future<bool> removeFromCart(String userId, String productId) async{
  try {
    // Firestore 인스턴스를 가져옵니다.
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    // 사용자의 'cart' 컬렉션에서 특정 'productId' 문서를 삭제합니다.
    await firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .delete();

    // 삭제가 성공했을 경우 true를 반환합니다.
    return true;
  } catch (e) {
    // 삭제 중 오류가 발생한 경우, 오류를 콘솔에 출력하고 false를 반환합니다.
    print("장바구니에서 항목을 삭제하는 데 실패했습니다: $e");
    return false;
  }
}

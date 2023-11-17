import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:preorder/components/appbar.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getUnfinishedOrderDocumentId(String uid) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('orders')
          .where('uid', isEqualTo: uid)
          .where('status', isNotEqualTo: 'FINISHED')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // 첫 번째 미완료 주문 문서의 ID 반환
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print("Error getting unfinished order document ID: $e");
      return null;
    }
  }
}

void navigateToOrderStatusPage(BuildContext context, String uid) async {
  OrderService orderService = OrderService();
  String? orderId = await orderService.getUnfinishedOrderDocumentId(uid);

  if (orderId != null) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderStatusPage(orderId: orderId),
      ),
    );
  } else {
    // 적절한 에러 처리나 메시지 표시
    print('No unfinished orders found for user with uid: $uid');
  }
}

class OrderStatusPage extends StatefulWidget {
  final String orderId;

  OrderStatusPage({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderStatusPageState createState() => _OrderStatusPageState();
}

Widget _buildOrderStatusText(String status, String text, bool isActive) {
  return Text(
    text,
    style: TextStyle(
      color: isActive ? Color(0xFFEF7474) : Colors.black,
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    ),
  );
}

Widget _buildOrderStatusIndicator(String status) {
  // 주문 상태에 따른 게이지의 너비 비율과 활성화 상태를 결정합니다.
  double widthFactor;
  bool isPaymentCompleteActive, isPreparingActive, isReadyActive;
  isPaymentCompleteActive = isPreparingActive = isReadyActive = false;

  switch (status) {
    case 'ORDER':
      widthFactor = 0.0;
      isPaymentCompleteActive = true;
      break;
    case 'ACCEPTED':
      widthFactor = 0.5;
      isPaymentCompleteActive = isPreparingActive = true;
      break;
    case 'READY':
      widthFactor = 1.0;
      isPaymentCompleteActive = isPreparingActive = isReadyActive = true;
      break;
    case 'FINISHED':
      widthFactor = 1.0;
      isPaymentCompleteActive = isPreparingActive = isReadyActive = true;
    default:
      widthFactor = 0.0;
      break;
  }

  return Column(
    children: [
      Stack(
        children: [
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          FractionallySizedBox(
            widthFactor: widthFactor,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Color(0xFFEF7474),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildOrderStatusText(status, '결제 완료', isPaymentCompleteActive),
            _buildOrderStatusText(status, '준비 중', isPreparingActive),
            _buildOrderStatusText(status, '제조 완료', isReadyActive),
          ],
        ),
      ),
    ],
  );
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  Widget _buildCartItem(Map<String, dynamic> item) {
    // 상품 옵션을 위젯으로 변환합니다.
    var optionsWidgets = List<Widget>.from(
      (item['options'] as List).map(
        (option) => Text(
          '${option['optionName'] ?? ''}: ${option['optionPrice'] ?? ''}',
          style: TextStyle(fontSize: 14),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품 이미지를 표시할 Container
          Container(
            width: 80.0,
            height: 80.0,
            decoration: BoxDecoration(
              color: Colors.grey[200], // 임시 색상
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          SizedBox(width: 16.0),
          // 상품 이름과 옵션들을 표시할 Expanded
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['productName'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                ...optionsWidgets,
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item['itemPrice'].toString()}원',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              Text(
                '수량: ${item['quantity'].toString()}',
                style: TextStyle(
                  color: Color(0xff8A8484),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTotalPriceSection(double totalPrice) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '결제 금액',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${totalPrice.toInt().toString()}원',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '주문 현황', centerTitle: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다.'));
          } else if (!snapshot.hasData || snapshot.data?.data() == null) {
            return Center(child: Text('주문 정보를 찾을 수 없습니다.'));
          } else {
            Map<String, dynamic> orderData =
                snapshot.data!.data() as Map<String, dynamic>;

            String status = orderData['status'] ?? '처리중';

            String orderStatusMessage;
            switch (status) {
              case 'ORDER':
                orderStatusMessage = '주문 확인하고 있습니다.';
              case 'ACCEPTED':
                orderStatusMessage = '만들고 있습니다.';
                break;
              case 'READY':
                orderStatusMessage = '준비 완료했습니다.';
                break;
              case 'FINISHED':
                orderStatusMessage = '픽업 완료했습니다.';
                break;
              default:
                orderStatusMessage = '처리중'; // 기본값 설정
                break;
            }
            String orderId = orderData['orderId'].toString() ?? '알 수 없는 주문';

            // 'timestamp' 필드를 가져와서 DateTime 객체로 변환합니다.
            Timestamp timestamp = orderData['timestamp'] as Timestamp;
            DateTime dateTime = timestamp.toDate();
            int pickupMinutes =
                orderData['pickupTime'] as int; // pickupTime을 분 단위로 가져옵니다.
            DateTime pickupTime =
                dateTime.add(Duration(minutes: pickupMinutes)); // pickupTime 계산
            List<dynamic> items = orderData['items'];

            // intl 패키지를 사용하여 원하는 형식으로 날짜를 포매팅합니다.
            String formattedTime =
                DateFormat('yyyy. MM. dd. kk:mm').format(dateTime);
            String formattedPickupTime =
                DateFormat('yyyy. MM. dd. kk:mm').format(pickupTime);
            return ListView(
              padding: EdgeInsets.all(16.0),
              children: <Widget>[
                Text(
                  '도서관 카페점에서\n${FirebaseAuth.instance.currentUser?.email ?? 'Unknown'}님의 음료를\n$orderStatusMessage',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  '주문 번호: $orderId',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  '주문 시간: $formattedTime',
                  style: TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '픽업 타임: $formattedPickupTime', // 픽업 시간을 표시합니다.
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 20),
                _buildOrderStatusIndicator(status),
                SizedBox(height: 20),
                ...items.map((item) => _buildCartItem(item)).toList(),
                SizedBox(height: 20),
                Divider(
                  color: Color(0xFFDDDDDD),
                  thickness: 1, // 줄의 두께 설정
                ),
                _buildTotalPriceSection(orderData['totalPrice']),
                // 기타 UI 컴포넌트들...
              ],
            );
          }
        },
      ),
    );
  }
}

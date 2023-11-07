import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

class _OrderStatusPageState extends State<OrderStatusPage> {
  @override
  Widget build(BuildContext context) {
    // Firestore 인스턴스
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('주문 현황'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // 주문 문서에 대한 실시간 스트림을 설정합니다.
        stream: firestore.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 데이터를 불러오는 중이라면 로딩 인디케이터를 표시합니다.
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // 에러가 발생했다면 에러 메시지를 표시합니다.
            return Center(child: Text('오류가 발생했습니다.'));
          }

          if (!snapshot.hasData) {
            // 문서 데이터가 없다면 알림 메시지를 표시합니다.
            return Center(child: Text('주문 정보를 찾을 수 없습니다.'));
          }

          // 문서 데이터가 있으면 주문 상태를 표시합니다.
          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
          String status = data['status'] ?? '처리중';

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('주문 상태: $status', style: TextStyle(fontSize: 24)),
                // 주문 상태에 따라 추가적인 UI 컴포넌트를 여기에 배치할 수 있습니다.
              ],
            ),
          );
        },
      ),
    );
  }
}

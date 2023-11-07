import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});


  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    User? currentUser = auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 내역'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 현재 로그인한 사용자의 uid와 일치하는 주문만 스트림으로 가져옵니다.
        stream: firestore.collection('orders')
            .where('uid', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
            return const Center(child: Text('주문 내역이 없습니다'));
          }

          return ListView.builder(
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context, index) {
              var orderData = snapshot.data?.docs[index].data() as Map<String, dynamic>;

              // 여기서 각 주문에 대한 위젯을 만듭니다.
              // 예를 들어, 주문 이름과 총 가격을 표시할 수 있습니다.
              return ListTile(
                title: Text(orderData['productName']),
                subtitle: Text('총 가격: ₩${orderData['totalPrice']}'),
                trailing: Text('수량: ${orderData['quantity']}'),
              );
            },
          );
        },
      ),
    );
  }
}

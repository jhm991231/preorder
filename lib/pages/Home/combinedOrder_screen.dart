import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:preorder/pages/Home/orderList_screen.dart';
import 'package:preorder/pages/Home/orderStatus_screen.dart';

class CombinedOrderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 탭의 개수
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 5,
          bottom: const TabBar(
            tabs: [
              Tab(text: '주문 현황'),
              Tab(text: '주문 내역'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OrderStatusTab(),
            OrderListScreen(),
          ],
        ),
      ),
    );
  }
}

class OrderStatusTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String userUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final OrderService orderService = OrderService();

    return userUid.isEmpty
        ? Center(child: Text('로그인이 필요합니다.'))
        : FutureBuilder<String?>(
            future: orderService.getUnfinishedOrderDocumentId(userUid),
            builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('오류가 발생했습니다.'));
              } else if (!snapshot.hasData) {
                return Center(child: Text('미완료된 주문이 없습니다.'));
              } else {
                return OrderStatusPage(orderId: snapshot.data!);
              }
            },
          );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // 상태에 알맞은 텍스트로 변환
  String getStatusText(String status) {
    switch (status) {
      case "ORDER":
        return "접수 대기";
      case "ACCEPTED":
        return "준비 중";
      case "READY":
        return "준비 완료";
      case "FINISHED":
        return "픽업 완료";
      default:
        return "상태 불명";
    }
  }
  
  // 음료 여러 개 주문 시 -> ...외 x개 로 만들기
  String getProductNameText(List<dynamic> items) {
    if (items.length == 1) {
      return items[0]['productName'];
    } else if (items.length > 1) {
      return '${items[0]['productName']} 외 ${items.length - 1}개';
    } else {
      return '주문한 음료 없음';
    }
  }

  // 숫자로 된 금액을 -> 1,000,000원 으로 변환
  String formatCurrency(num totalPrice) {
    final formatCurrency = NumberFormat.simpleCurrency(
        locale: 'ko_KR', name: 'KRW', decimalDigits: 0);
    return formatCurrency.format(totalPrice);
  }

  // order data에 있는 timestamp를 "2023년 05월
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('주문 내역', style: TextStyle(color: Colors.white),)),
        backgroundColor: const Color(0xff303742),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 현재 로그인한 사용자의 uid와 일치하는 주문만 스트림으로 가져옵니다.
        stream: firestore
            .collection('orders')
            .where('uid', isEqualTo: currentUser?.uid)
            .orderBy('timestamp', descending: true) // 시간순으로 최신이 위로 오게 정렬
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
            return const Center(child: Text('주문 내역이 없습니다'));
          }

          return ListView.builder(
            itemCount: snapshot.data?.docs.length,
            itemBuilder: (context, index) {
              var orderData =
                  snapshot.data?.docs[index].data() as Map<String, dynamic>;
              String statusText = getStatusText(orderData["status"]);
              String productNameText = getProductNameText(orderData["items"]);
              //DateTime timestamp = (orderData["timestamp"] as Timestamp).toDate();
              // 여기서 각 주문에 대한 위젯을 만듭니다.
              // 예를 들어, 주문 이름과 총 가격을 표시할 수 있습니다.
              return Container(
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey), // 회색 테두리를 추가합니다.
                  borderRadius: BorderRadius.circular(4.0), // 모서리를 약간 둥글게 합니다.
                  color: Colors.white, // 배경색을 흰색으로 설정합니다.
                ),
                child: ListTile(
                  title: Text(
                    productNameText,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    formatTimestamp(orderData["timestamp"]),
                    style: const TextStyle(fontSize: 15),
                  ),
                  // 타임스탬프를 로컬 시간으로 변환하여 표시
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        statusText,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatCurrency(orderData["totalPrice"]),
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

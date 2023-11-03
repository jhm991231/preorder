import 'package:flutter/material.dart';
import 'make_order.dart';

class CartScreen extends StatelessWidget {
  final String userId;

  CartScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('장바구니'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchCartItems(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text("오류가 발생했습니다.");
          } else if (snapshot.hasData) {
            var cartItems = snapshot.data!;
            return ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                var item = cartItems[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text('가격: ${item['price']}원'),
                  // 추가적인 아이템 디자인
                );
              },
            );
          } else {
            return Text("장바구니가 비어 있습니다.");
          }
        },
      ),
    );
  }
}

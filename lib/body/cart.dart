import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [
    {"name": "아메리카노", "quantity": 1, "price": 4000},
    // 다른 아이템들...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("장바구니"),
        backgroundColor: Color(0xff303742), // AppBar 색상 설정
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close), // 'X' 아이콘
          onPressed: () {
            context.go('/home');
            }, // 이전 화면으로 돌아가기
        ),
      ),
      body: ListView.builder(
        itemCount: cartItems.length,
        itemBuilder: (context, index) {
          final item = cartItems[index];
          return ListTile(
            title: Text(item['name']),
            subtitle: Text("수량: ${item['quantity']}"),
            trailing: Wrap(
              spacing: 12,
              children: <Widget>[
                Text("가격: ${item['price']}원"),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _removeItemFromCart(index),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 50.0,
          child: Center(
            child: Text(
              "총 가격: ${calculateTotal()}원",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _removeItemFromCart(int index) {
    setState(() {
      cartItems.removeAt(index);
    });
  }

  double calculateTotal() {
    return cartItems.fold(0, (total, current) => (total + (current['price'] * current['quantity'])));
  }
}

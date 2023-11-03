import 'package:flutter/material.dart';
import 'make_order.dart';

class CartScreen extends StatefulWidget {
  final String userId;

  CartScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Map<String, dynamic>>> cartItemsFuture;

  @override
  void initState() {
    super.initState();
    cartItemsFuture = fetchCartItems(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '장바구니',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: cartItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('장바구니가 비어있습니다.'));
          } else {
            List<Map<String, dynamic>> cartItems = snapshot.data!;
            return Column(
              children: [
                _selectionSection(),
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      var item = cartItems[index];
                      var optionsWidgets = (item['options'] as List<Map<String, dynamic>>).map((option) {
                        return Text('${option['optionName'] ?? ''}: ${option['optionPrice'] ?? ''}원');
                      }).toList();

                      return ListTile(
                        title: Text(item['productName']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...optionsWidgets,
                          ],
                        ),
                        trailing: Text('${item['productPrice']}원'),
                      );
                    },
                  ),
                ),
                _totalAmountSection(cartItems),
                _purchaseButton(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _selectionSection() {
    return ListTile(
      leading: Checkbox(value: false, onChanged: null),
      title: Text('전체 선택 (0/2)'),
      trailing: Text('전체 삭제'),
    );
  }

  Widget _totalAmountSection(List<Map<String, dynamic>> cartItems) {
    var totalAmount = 0.0;
    cartItems.forEach((item) {
      totalAmount += item['productPrice'];
    });
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('상품금액'),
              Text('$totalAmount원'),
            ],
          ),
          // 할인금액이 필요하면 추가로 Row를 하나 더 만들면 됩니다.
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('결제예정금액', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$totalAmount원', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _purchaseButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Colors.blue,
        ),
        onPressed: () {
          DateTime pickupTime = DateTime.now().add(Duration(hours: 1)); // 예제용
          processOrder(widget.userId, pickupTime);
        },
        child: Text('주문하기', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}


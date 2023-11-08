// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'make_order.dart';

class OrderScreen extends StatefulWidget {
  final String userId;

  OrderScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late Future<List<Map<String, dynamic>>> cartItemsFuture;

  TextEditingController _specialRequestController = TextEditingController();
  int _selectedTime = 1; // Default time

  @override
  void initState() {
    super.initState();
    cartItemsFuture = fetchCartItems(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff303742),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '주문하기',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: cartItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('결제할 제품이 없습니다'));
          } else {
            List<Map<String, dynamic>> cartItems = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      var item = cartItems[index];
                      return _buildCartItem(item);
                    },
                  ),
                ),
                _specialRequestsSection(),
                _arrivalTimeSelectionSection(),
                _totalAmountSection(cartItems),
                _purchaseButton(),
              ],
            );
          }
        },
      ),
    );
  }

  void _removeItemFromCart(String productId) async {
    bool success = await removeFromCart(widget.userId, productId);
    if (success) {
      setState(() {
        cartItemsFuture = fetchCartItems(widget.userId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("항목을 삭제하는데 실패했습니다.")),
      );
    }
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    // 상품 옵션을 위젯으로 변환합니다.
    var optionsWidgets = (item['options'] as List<Map<String, dynamic>>)
        .map((option) => Text(
        '${option['optionName'] ?? ''}: ${option['optionPrice'] ?? ''}원'))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상품 사진
          Container(
            width: 80.0,
            height: 80.0,
            color: Colors.grey, // 임시 색상, 여기에 이미지 위젯을 넣을 수 있습니다.
          ),
          // 상품 이름과 옵션들
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['productName'],
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${item['productPrice'].toString()}원',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...optionsWidgets, // 옵션 리스트
                  // 수량 등 추가적인 정보를 여기에 추가할 수 있습니다.
                ],
              ),
            ),
          ),
          // X 버튼
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _removeItemFromCart(item['productId']);
                },
              ),
              Text(
                '수량: ${item['quantity']}',
                style: const TextStyle(color: Color(0xff8A8484)),
              ),
              // '수량' 부분을 오른쪽 아래에 위치
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalAmountSection(List<Map<String, dynamic>> cartItems) {
    var totalAmount = 0.0;

    for (var item in cartItems) {
      totalAmount += item['productPrice'] ?? 0;
    }

    String totalAmountString = totalAmount
        .toStringAsFixed(totalAmount.truncateToDouble() == totalAmount ? 0 : 2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('상품금액'),
              Text('$totalAmountString원'),
            ],
          ),
          // 할인금액이 필요하면 추가로 Row를 하나 더 만들면 됩니다.
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('결제금액', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$totalAmountString원',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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
            backgroundColor: const Color(0xff303732),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            )),
        onPressed: () async {

          bool orderProcessed = await processOrder(widget.userId, _selectedTime);

          // 여기서 processOrder는 Future<bool>을 반환하고, 주문 처리가 성공했는지 여부를 알려줍니다.
          if (orderProcessed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Center(child: Text("주문이 완료되었습니다"))),
            );
            // 주문 처리가 성공하면, Navigator를 사용하여 주문현황 화면으로 가기
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
            // 주문 처리에 실패했을 때는 오류 메시지를 보여주는 등의 처리를 할 수 있습니다.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("결제 처리에 실패했습니다. 다시 시도해주세요.")),
            );
          }
        },
        child: const Text('결제하기', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _specialRequestsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _specialRequestController,
        decoration: const InputDecoration(
          labelText: '요청사항',
          border: OutlineInputBorder(),
          hintText: '특별 요청 사항이 있다면 입력해주세요',
        ),
        keyboardType: TextInputType.text,
      ),
    );
  }

  Widget _arrivalTimeSelectionSection() {
    return ListTile(
      title: Text('도착 예상 시간: $_selectedTime 분 후'),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: _showTimeSelection,
    );
  }

  void _showTimeSelection() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: 20,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text('${index + 1}'),
              onTap: () {
                setState(() {
                  _selectedTime = index + 1;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}

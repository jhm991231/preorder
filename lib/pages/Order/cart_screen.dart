import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:preorder/make_order.dart';

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

  Future<String> loadImage(String drinkName) async {
    String imagePath = 'gs://preorder-d773a.appspot.com/$drinkName.jpg';
    Reference storageReference = FirebaseStorage.instance.refFromURL(imagePath);

    String imageUrl = await storageReference.getDownloadURL();
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff303742),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '장바구니',
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
            return const Center(child: Text('장바구니가 비어있습니다'));
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
                      return _buildCartItem(item);
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

  void _removeItemFromCart(String productId) async {
    bool success = await removeFromCart(widget.userId, productId);
    if (success) {
      // UI를 업데이트하기 위해 cartItemsFuture를 다시 설정합니다.
      setState(() {
        cartItemsFuture = fetchCartItems(widget.userId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("항목을 삭제하는데 실패했습니다.")),
      );
    }
  }

  void _removeAllItemsFromCart() async {
    bool success = await clearCart(widget.userId);
    if (success) {
      // 모든 항목을 삭제했다면, UI를 업데이트하기 위해 cartItemsFuture를 다시 설정합니다.
      setState(() {
        cartItemsFuture = fetchCartItems(widget.userId);
      });
      // 삭제 성공 메시지를 보여줍니다.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 항목이 삭제되었습니다.")),
      );
    } else {
      // 삭제 실패 메시지를 보여줍니다.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("항목을 삭제하는데 실패했습니다. 다시 시도해주세요.")),
      );
    }
  }

  Widget _selectionSection() {
    return ListTile(
      leading: const Text(
        '주문 상품',
        style: TextStyle(
          fontSize: 16.0,
          color: Colors.black,
        ),
      ),
      trailing: TextButton(
        onPressed: () {
          _removeAllItemsFromCart();
          print('전체 삭제 버튼이 눌렸습니다.');
        },
        child: const Text(
          '전체 삭제',
          style: TextStyle(
              color: Colors.black54, fontSize: 12.0), // 색상은 원하는 대로 조정할 수 있습니다.
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    // 상품 옵션을 위젯으로 변환합니다.
    var optionsWidgets = (item['options'] as List<Map<String, dynamic>>)
        .map((option) => Text(
            '${option['optionName'] ?? ''}: ${option['optionPrice'] ?? ''}원'))
        .toList();

    bool isForMe = item['isForMe'] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
// 상품 사진과 'MY' 라벨을 Stack으로 구성
          Stack(
            alignment: Alignment.topLeft,
            children: [
              // 상품 사진을 FutureBuilder를 사용하여 로드합니다.
              FutureBuilder<String>(
                future: loadImage(item['productName']),
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  Widget imageWidget;
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    imageWidget = Image.network(
                      snapshot.data!,
                      width: 80.0,
                      height: 80.0,
                      fit: BoxFit.cover,
                    );
                  } else {
                    imageWidget = Container(
                      width: 80.0,
                      height: 80.0,
                      color: Colors.grey, // 로딩 중 또는 오류 시 표시될 색상
                      child: snapshot.hasError
                          ? const Icon(Icons.error)
                          : CircularProgressIndicator(),
                    );
                  }
                  return imageWidget;
                },
              ),
              // '내가 먹을 음료'일 경우에만 'MY' 라벨을 표시
              if (isForMe)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  color: Colors.red, // 라벨의 배경 색상
                  child: Text(
                    'MY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
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
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${item['itemPrice'].toString()}원',
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
      totalAmount += (item['itemPrice'] * item['quantity']);
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
              const Text('결제예정금액',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$totalAmountString원',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
        onPressed: () {
          context.push('/order');
        },
        child: const Text('주문하기',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

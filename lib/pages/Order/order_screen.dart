// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:preorder/make_order.dart';

class OrderScreen extends StatefulWidget {
  final String userId;

  OrderScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late Future<List<Map<String, dynamic>>> cartItemsFuture;
  List<Map<String, dynamic>> cartItems = [];

  bool isLoading = true; // 로딩 상태를 추적하는 변수

  TextEditingController _specialRequestController = TextEditingController();
  int _selectedTime = 1; // Default time

  @override
  void initState() {
    super.initState();
    fetchCartItems(widget.userId).then((items) {
      setState(() {
        cartItems = items;
        isLoading = false; // 데이터 로딩 완료
      });
    }).catchError((error) {
      // 에러 처리
      setState(() {
        isLoading = false;
      });
    });
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
      resizeToAvoidBottomInset: true,
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    var item = cartItems[index];
                    return _buildCartItem(item);
                  },
                ),
                const SizedBox(
                  height: 18,
                ),
                _specialRequestsSection(),
                const SizedBox(
                  height: 18,
                ),
                _arrivalTimeSelectionSection(),
                const Spacer(),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _totalAmountSection(cartItems),
            _purchaseButton(),
          ],
        ),
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
          // 상품 사진을 FutureBuilder를 사용하여 로드합니다.
          FutureBuilder<String>(
            future: loadImage(item['productName']),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                return Image.network(
                  snapshot.data!,
                  width: 80.0,
                  height: 80.0,
                  fit: BoxFit.cover,
                );
              } else {
                return Container(
                  width: 80.0,
                  height: 80.0,
                  color: Colors.grey, // 로딩 중 또는 오류 시 표시될 색상
                  child: snapshot.hasError ? const Icon(Icons.error) : CircularProgressIndicator(),
                );
              }
            },
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
                    '${item['productPrice'].toString()}원',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...optionsWidgets, // 옵션 리스트
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
      totalAmount += item['itemPrice'] * item['quantity'] ?? 0;
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
          String specialRequest = _specialRequestController.text;

          bool orderProcessed =
              await processOrder(widget.userId, _selectedTime, specialRequest);

          // 여기서 processOrder는 Future<bool>을 반환하고, 주문 처리가 성공했는지 여부를 알려줍니다.
          if (orderProcessed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Center(child: Text("주문이 완료되었습니다"))),
            );
            for (var item in cartItems) {
              // 'drinks' 서브컬렉션에서 productName을 기준으로 쿼리
              var querySnapshot = await FirebaseFirestore.instance
                  .collectionGroup('drinks')
                  .where('productName', isEqualTo: item['productName'])
                  .get();

              for (var doc in querySnapshot.docs) {
                doc.reference.update({'sales': FieldValue.increment(1)});
              }
            }
            // 주문 처리가 성공하면, Navigator를 사용하여 주문현황 화면으로 가기
            context.go('/', extra: 1);
          } else {
            // 주문 처리에 실패했을 때는 오류 메시지를 보여주는 등의 처리를 할 수 있습니다.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("결제 처리에 실패했습니다. 다시 시도해주세요.")),
            );
          }
        },
        child: const Text('결제하기',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _specialRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Text('요청사항',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF969393))),
        ),
        Padding(
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
        ),
      ],
    );
  }

  Widget _arrivalTimeSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Text('도착 예정 시간',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF969393))),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListTile(
            title: Center(child: Text('${_selectedTime ?? '선택 안됨'} 분 후')),
            // 선택한 시간을 표시
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.grey, width: 1.0),
              // 경계선의 색상과 두께를 설정
              borderRadius: BorderRadius.circular(4.0), // 모서리의 둥글기를 설정
            ),
            trailing: const Icon(Icons.arrow_drop_down),
            onTap: _showTimeSelection,
          ),
        ),
      ],
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
              title: Center(child: Text('${index + 1}분 후')),
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

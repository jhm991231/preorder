import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OptionScreen extends StatefulWidget {
  final Map<String, dynamic> menu;

  OptionScreen({super.key, required this.menu});

  @override
  State<OptionScreen> createState() => _OptionScreenState();
}

class _OptionScreenState extends State<OptionScreen> {
  // List<Map<String, dynamic>> options = [];
  late Stream<QuerySnapshot<Map<String, dynamic>>> optionStream;
  Map<String, bool> optionCheckStatus = {};
  int selectedOptionPrice = 0;
  int quantity = 1;
  int productPrice = 0;

  @override
  void initState() {
    super.initState();
    optionStream = FirebaseFirestore.instance.collection('option').snapshots();
    productPrice = widget.menu['productPrice'];
  }

  void updateSelectedOptionPrice(int price, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedOptionPrice += price;
      } else {
        selectedOptionPrice -= price;
      }
    });
  }

  void increaseQuantity() {
    setState(() {
      quantity++;
    });
  }

  void decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  Future<void> addToCart() async {
    User? user = FirebaseAuth.instance.currentUser;
    List<Map<String, dynamic>> selectedOptions = [];
    for (var entry in optionCheckStatus.entries) {
      if (entry.value) {
        int optionPrice = 0;
        if (entry.key == "사이즈업") {
          optionPrice = 300;
        } else {
          optionPrice = 500;
        }
        selectedOptions.add({
          'optionName': entry.key,
          'optionPrice': optionPrice,
        });
      }
    }

    //int _productPrice = productPrice;
    int itemPrice = (productPrice + selectedOptionPrice);

    DocumentReference cartItemRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .doc();

    // 문서 ID를 가져옵니다. 이 ID는 Firestore에 의해 생성됩니다.
    String productId = cartItemRef.id;

    // Firestore 문서에 데이터를 추가합니다.
    await cartItemRef.set({
      'productId': productId, // 생성된 문서 ID를 productId 필드로 저장합니다.
      'productName': widget.menu['productName'],
      'productPrice': productPrice,
      'selectedOptions': selectedOptions,
      'quantity': quantity,
      'itemPrice': itemPrice,
      'status': 'IN_CART',
    });


    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Center(child: Text('장바구니에 추가되었습니다'))),
    );

    Navigator.pop(context);
  }

    @override
    Widget build(BuildContext context) {
      int totalPrice = (productPrice + selectedOptionPrice) * quantity;

      return Scaffold(
        appBar: AppBar(
          title: const Text("옵션 선택 화면", style: TextStyle(color: Colors.white),),
          backgroundColor: const Color(0xff303742),

        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: optionStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            List<DocumentSnapshot<Map<String, dynamic>>> optionDocs = snapshot
                .data!.docs;

            return Column(
              children: [
                const SizedBox(height: 20),
                // 간격 추가
                // 여기서 음료의 이미지를 표시
                if (widget.menu.containsKey('image_url') &&
                    widget.menu['image_url'] != null)

                  Image.network(widget.menu['image_url'], height: 150),
                // 이미지의 높이를 150으로 설정
                const SizedBox(height: 10),
                // 간격 추가
                Text(widget.menu['productName'],
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                // 음료 이름
                const SizedBox(height: 40),
                // 간격 추가
                const Text('옵션 선택', style: TextStyle(fontSize: 20),),
                const SizedBox(height: 20),
                // 간격 추가
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: optionDocs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> optionData = optionDocs[index]
                        .data() as Map<String, dynamic>;
                    bool isChecked = optionCheckStatus[optionData['optionName']] ??
                        false;

                    return ListTile(
                      title: Text(
                        optionData['optionName'], style: const TextStyle(
                          fontSize: 16),),
                      trailing: Text(
                        "${optionData['optionPrice']}원", style: const TextStyle(
                          fontSize: 16),),
                      leading: Checkbox(
                        value: isChecked,
                        onChanged: (bool? value) {
                          print(value);
                          setState(() {
                            optionCheckStatus[optionData['optionName']] =
                            value!;
                          });
                          updateSelectedOptionPrice(
                              (optionData['optionPrice']), value!);
                        },
                      ),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 30),
                      child: Text('수량', style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: decreaseQuantity, // 수량 감소 메서드 호출//
                          ),
                          Text("$quantity", style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: increaseQuantity, // 수량 증가 메서드 호출
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                Expanded(child: Container()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('상품금액', style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),),
                      Text(
                        '${NumberFormat("#,###").format(totalPrice)}원',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                    ],
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async{
                    await addToCart();
                  } ,
                  child: Container(
                    height: 40.0,
                    // 버튼의 높이를 설정합니다.
                    width: double.infinity,
                    // 버튼의 너비를 화면 전체로 설정합니다.
                    decoration: BoxDecoration(
                      color: const Color(0x8CC0C0C0), // 배경색을 설정합니다.
                      borderRadius: BorderRadius.circular(
                          10), // 모서리를 둥글게 설정합니다.
                    ),
                    alignment: Alignment.center,
                    // 내부의 텍스트를 중앙으로 정렬합니다.
                    child: const Text(
                      '장바구니',
                      style: TextStyle(
                        color: Colors.black, // 텍스트 색상을 검정색으로 설정합니다.
                        fontSize: 16.0, // 텍스트 크기를 설정합니다.
                      ),
                    ),
                  ),
                ),

              ),
              const SizedBox(width: 10,),
              Expanded(
                child: GestureDetector(
                  onTap: () async{
                    await addToCart();
                    context.push("/order");
                  },
                  child: Container(
                    height: 40.0,
                    // 버튼의 높이를 설정합니다.
                    width: double.infinity,
                    // 버튼의 너비를 화면 전체로 설정합니다.
                    decoration: BoxDecoration(
                      color: const Color(0x8CC0C0C0), // 배경색을 설정합니다.
                      borderRadius: BorderRadius.circular(
                          10), // 모서리를 둥글게 설정합니다.
                    ),
                    alignment: Alignment.center,
                    // 내부의 텍스트를 중앙으로 정렬합니다.
                    child: const Text(
                      '주문하기',
                      style: TextStyle(
                        color: Colors.black, // 텍스트 색상을 검정색으로 설정합니다.
                        fontSize: 16.0, // 텍스트 크기를 설정합니다.
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

        ),
      );
    }
  }


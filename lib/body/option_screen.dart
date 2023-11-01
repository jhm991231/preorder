import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class OptionScreen extends StatefulWidget {
  final Map<String, dynamic> menu;

  OptionScreen({required this.menu});

  @override
  State<OptionScreen> createState() => _OptionScreenState();
}

class _OptionScreenState extends State<OptionScreen> {
  // List<Map<String, dynamic>> options = [];
  late Stream<QuerySnapshot<Map<String, dynamic>>> optionStream;
  Map<String, bool> optionCheckStatus = {};
  int selectedOptionPrice = 0;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    optionStream = FirebaseFirestore.instance.collection('option').snapshots();
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
    if (quantity > 1 ) {
      setState(() {
        quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int price = int.parse(widget.menu['price'].replaceAll(',', '').replaceAll('원', ''));

    int totalPrice = (price + selectedOptionPrice) * quantity;

    return Scaffold(
      appBar: AppBar(
        title: Text("옵션 선택 화면"),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: optionStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
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
              Text(widget.menu['name'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  bool isChecked = optionCheckStatus[optionData['옵션명']] ?? false;

                  return ListTile(
                    title: Text(optionData['옵션명'], style: const TextStyle(
                        fontSize: 16),),
                    trailing: Text("${optionData['가격']}원", style: const TextStyle(
                        fontSize: 16),),
                    leading: Checkbox(
                      value: isChecked,
                      onChanged: (bool? value) {
                        print(value);
                        setState(() {
                          optionCheckStatus[optionData['옵션명']] = value!;
                        });
                        updateSelectedOptionPrice((optionData['가격']), value!);
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
                    child: Text('수량', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: decreaseQuantity,  // 수량 감소 메서드 호출//
                        ),
                        Text("$quantity", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: increaseQuantity,  // 수량 증가 메서드 호출
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
                    const Text('상품금액', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                    Text(
                      '${NumberFormat("#,###").format(totalPrice)}원',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    // Text(
                    //   '${NumberFormat("#,###").format((price + selectedOptionPrice)*quantity)}원',
                    //   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    // ),

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
                onTap: () {
                  // 장바구니 로직 추가
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Center(child: Text("장바구니에 추가 되었습니다")),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Container(
                  height: 40.0, // 버튼의 높이를 설정합니다.
                  width: double.infinity, // 버튼의 너비를 화면 전체로 설정합니다.
                  decoration: BoxDecoration(
                    color: const Color(0x8CE7E7E7), // 배경색을 설정합니다.
                    borderRadius: BorderRadius.circular(0), // 모서리를 둥글게 설정합니다.
                  ),
                  alignment: Alignment.center, // 내부의 텍스트를 중앙으로 정렬합니다.
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
            SizedBox(width: 10,),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // 주문하기 로직 추가
                },
                child: Container(
                  height: 40.0, // 버튼의 높이를 설정합니다.
                  width: double.infinity, // 버튼의 너비를 화면 전체로 설정합니다.
                  decoration: BoxDecoration(
                    color: const Color(0x8CE7E7E7), // 배경색을 설정합니다.
                    borderRadius: BorderRadius.circular(0), // 모서리를 둥글게 설정합니다.
                  ),
                  alignment: Alignment.center, // 내부의 텍스트를 중앙으로 정렬합니다.
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

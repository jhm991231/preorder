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
  int selectedOptionPrice = 0;

  @override
  void initState() {
    super.initState();
    optionStream = FirebaseFirestore.instance.collection('option').snapshots();
  }

  void updateSelectedOptionPrice(String price_str, bool isSelected) {
    int price = int.parse(price_str);
    setState(() {
      if (isSelected) {
        selectedOptionPrice += price;
      } else {
        selectedOptionPrice -= price;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    int price = int.parse(widget.menu['price'].replaceAll(',', '').replaceAll('원', ''));
    Map<String, bool> optionCheckStatus = {};


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
              Expanded(
                child: ListView.builder(
                  itemCount: optionDocs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> optionData = optionDocs[index]
                        .data() as Map<String, dynamic>;
                    bool isChecked = optionCheckStatus[optionData['옵션명']] ?? false;


                    return ListTile(
                      title: Text(optionData['옵션명'], style: TextStyle(
                          fontSize: 16),),
                      trailing: Text("${optionData['가격']}원", style: TextStyle(
                          fontSize: 16),),
                      leading: Checkbox(
                        value: isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            optionCheckStatus[optionData['옵션명']] = value!;
                          });
                          updateSelectedOptionPrice((optionData['가격']), value!);
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('상품금액', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                    Text(
                      '${NumberFormat("#,###").format(price + selectedOptionPrice)}원',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Color(0x8CE7E7E7),
                    shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  )
                ),
                child: Text('장바구니'),
                onPressed: () {
                  print("Type of widget.menu['price']: ${widget.menu['price'].runtimeType}");
                  // 장바구니 로직 추가
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Center(child: Text("장바구니에 추가 되었습니다")),
                    ),
                  );
                  context.push('/home');

                },
              ),
            ),
            SizedBox(width: 10,),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Color(0x8CE7E7E7),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    )
                ),
                child: Text('주문하기'),
                onPressed: () {
                  //주문 로직 추가
                },
              ),
            ),
          ],
        ),

      ),
    );
  }
}

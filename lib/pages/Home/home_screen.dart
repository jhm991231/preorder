import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:preorder/pages/Order/option_screen.dart';
import 'package:preorder/components/appbar.dart';
import 'package:preorder/components/logout_confirmation_dialog.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "COFFEE(ICE)";

  void updateCategory(String newCategory) {
    setState(() {
      selectedCategory = newCategory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "cafe",
        actions: <Widget>[
          IconButton(
            onPressed: () => showLogoutConfirmation(context),
            icon: const Icon(Icons.logout),
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag),
            color: Colors.white,
            onPressed: () {
              context.push('/cart');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          CategoryBar(
            onCategorySelect: updateCategory,
          ),
          MenuList(
            selectedCategory: selectedCategory,
          ),
        ],
      ),
    );
  }
}

class CategoryBar extends StatefulWidget {
  final Function(String) onCategorySelect;

  CategoryBar({required this.onCategorySelect});

  @override
  _CategoryBarState createState() => _CategoryBarState();
}

class _CategoryBarState extends State<CategoryBar> {
  final List<String> categories = [
    "BEST SELLERS",
    "COFFEE(ICE)",
    "COFFEE(HOT)",
    "BEVERAGE",
    "FRUIT TEA & BLENDING TEA",
    "MILK TEA & BUBBLE TEA",
    "ADE & ICE TEA"
  ];

  String selectedCategory = "COFFEE(ICE)";

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = categories[index] == selectedCategory;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedCategory = categories[index];
                });
                widget.onCategorySelect(categories[index]);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    categories[index],
                    style: TextStyle(
                      color: isSelected ? Color(0xff303742) : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  isSelected
                      ? Container(
                          width: 20.0,
                          height: 2.0,
                          color: Color(0xff303742),
                        )
                      : Container(),
                ],
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.transparent,
                onPrimary: Color(0xff303742),
                shadowColor: Colors.transparent,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MenuList extends StatefulWidget {
  final String selectedCategory;

  MenuList({Key? key, required this.selectedCategory}) : super(key: key);

  @override
  _MenuListState createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
  List<Map<String, dynamic>> menus = [];

  @override
  void initState() {
    super.initState();
    fetchMenus();
  }

  @override
  void didUpdateWidget(covariant MenuList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // selectedCategory가 변경되었을 때 fetchMenus를 다시 호출
    if (widget.selectedCategory != oldWidget.selectedCategory) {
      fetchMenus();
    }
  }

  Future<void> fetchMenus() async {
    try {
      if (widget.selectedCategory == "BEST SELLERS") {
        var querySnapshot = await FirebaseFirestore.instance
            .collectionGroup('drinks')
            .orderBy('sales', descending: true)
            .limit(5)
            .get();

        var fetchedMenus = querySnapshot.docs.map((doc) {
          return doc.data() as Map<String, dynamic>;
        }).toList();

        setState(() {
          menus = fetchedMenus;
        });
      }
      // 'category' 컬렉션에서 선택된 카테고리 문서에 접근
      else {
        var categoryDoc = FirebaseFirestore.instance
            .collection('category')
            .doc(widget.selectedCategory);

        // 'drinks' 서브 컬렉션에서 메뉴 데이터 가져오기
        var querySnapshot = await categoryDoc.collection('drinks').get();

        // Firestore 문서를 Dart 객체로 변환
        var fetchedMenus = querySnapshot.docs.map((doc) {
          return doc.data() as Map<String, dynamic>;
        }).toList();

        // 상태 업데이트
        setState(() {
          menus = fetchedMenus;
        });
      }
    } catch (e) {
      print(e);
      // 오류 처리 (예: 사용자에게 메시지 표시)
    }
  }

  Future<String> loadImage(String drinkName) async {
    String imagePath = 'gs://preorder-d773a.appspot.com/$drinkName.jpg';
    Reference storageReference = FirebaseStorage.instance.refFromURL(imagePath);

    String imageUrl = await storageReference.getDownloadURL();
    return imageUrl;
  }


  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: menus.length,
        itemBuilder: (BuildContext context, int index) {
          return FutureBuilder<String>(
            future: loadImage(menus[index]["productName"]),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              Widget imageWidget;
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                imageWidget = Container(
                  width: 70, // 이미지에 할당할 가로 크기
                  height: 100, // 이미지에 할당할 세로 크기
                  child: Image.network(snapshot.data!, fit: BoxFit.fill),
                );
              } else {
                imageWidget = const CircularProgressIndicator(); // 로딩 중 표시
              }

              return Container(
                height: 135.0,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xffDDDDDB)),
                  ),
                ),
                child: ListTile(
                  leading: imageWidget, // 이미지 추가
                  contentPadding: const EdgeInsets.symmetric(vertical: 13.5, horizontal: 36.0),
                  title: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menus[index]["productName"],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        Text(
                          '${menus[index]["productPrice"].toString()}원',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    // 메뉴 항목 클릭 시 액션 구현
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OptionScreen(menu: menus[index]),
                      ),
                    );
                    print("${menus[index]["productName"]} 선택됨");
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "COFFEE(ICE)";
  int _selectedIndex = 0;

  void updateCategory(String newCategory) {
    setState(() {
      selectedCategory = newCategory;
    });
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      context.go("/login");
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("로그아웃 실패 : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          title: "cafe",
          actions: <Widget>[
            IconButton(
              onPressed: () => signOut(context),
              icon: const Icon(Icons.logout),
            ),
            IconButton(
              icon: const Icon(Icons.shopping_bag),
              onPressed: () {
                context.go('/cart');
              },
            ),
          ],
        ),
        body: Column(
          children: [
            CategoryBar(
              onCategorySelect: updateCategory,
            ),
            MenuList(selectedCategory: selectedCategory,),
          ],
        ),
        );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  CustomAppBar({required this.title, this.actions});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      backgroundColor: Color(0xff303742),
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
            padding: EdgeInsets.symmetric(horizontal: 10.0),
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
                  SizedBox(height: 4.0),
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
      // 'category' 컬렉션에서 선택된 카테고리 문서에 접근
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
    } catch (e) {
      print(e);
      // 오류 처리 (예: 사용자에게 메시지 표시)
    }
  }


  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: menus.length,
        itemBuilder: (BuildContext context, int index) {
          return Container(
            height: 135.0,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
              color: Color(0xffDDDDDB),
            ))),
            child: ListTile(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 13.5, horizontal: 36.0),
              title: Padding(
                padding: EdgeInsets.only(left: 110.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menus[index]["productName"],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '${menus[index]["productPrice"].toString()}원',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  ],
                ),
              ),
              onTap: () {
                // 메뉴 항목 클릭 시 액션 구현
                print("${menus[index]["name"]} 선택됨");
              },
            ),
          );
        },
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/menu_data.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "커피(ICE)";
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
            MenuList(menus: menuData[selectedCategory] ?? []),
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
    "커피(ICE)",
    "커피(HOT)",
    "BEVERAGE",
    "FRUIT TEA",
    "밀크티&버블티",
    "에이드&주스"
  ];

  String selectedCategory = "커피(ICE)";

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

class MenuList extends StatelessWidget {
  final List<Map<String, dynamic>> menus;

  MenuList({required this.menus});

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
                      menus[index]["name"],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      menus[index]["price"],
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

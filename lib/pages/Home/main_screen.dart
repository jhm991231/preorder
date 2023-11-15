import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:preorder/pages/Home/orderList_screen.dart';
import 'package:preorder/pages/Home/orderStatus_screen.dart';
import 'package:preorder/pages/Home/mypage_screen.dart'; // MyPage 위젯을 가져옵니다.
import 'package:preorder/pages/Home/home_screen.dart'; // HomeScreen 위젯을 가져옵니다.

class MainScreen extends StatefulWidget {
  final int initialIndex;

  MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  final OrderService orderService = OrderService();

  // 현재 선택된 인덱스에 따라 위젯을 반환하는 함수
  Widget _buildWidgetOption(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        final String userUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (userUid.isEmpty) {
          // UID가 비어있다면 로그인이 필요하다는 메시지를 표시합니다.
          return Center(child: Text('로그인이 필요합니다.'));
        }
        // 미완료된 주문 ID를 가져옵니다.
        return FutureBuilder<String?>(
          future: orderService.getUnfinishedOrderDocumentId(userUid),
          builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Center(child: Text('오류가 발생했습니다.'));
            } else if (!snapshot.hasData) {
              return Center(child: Text('미완료된 주문이 없습니다.'));
            } else {
              // 미완료된 주문 ID가 있다면 OrderStatusPage 위젯을 생성하고 ID를 전달합니다.
              return OrderStatusPage(orderId: snapshot.data!);
            }
          },
        );
      case 2:
        return OrderListScreen();
      case 3:
        return MyPage();
      default:
        return HomeScreen(); // 기본값으로 홈 화면을 반환합니다.
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(4, (index) => _buildWidgetOption(index)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_cafe),
            label: '주문현황',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: '주문내역',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
          // ... 다른 네비게이션 아이템들
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black, // 선택된 아이템 색상
        unselectedItemColor: Colors.grey, // 선택되지 않은 아이템 색상
        showUnselectedLabels: true, // 선택되지 않은 레이블을 항상 보이게 합니다.
        showSelectedLabels: true,  // 선택된 레이블을 항상 보이게 합니다.
        onTap: _onItemTapped,
      ),
    );
  }
}

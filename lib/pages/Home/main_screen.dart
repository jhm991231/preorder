import 'package:flutter/material.dart';
import 'package:preorder/pages/Home/combinedOrder_screen.dart';
import 'package:preorder/pages/Home/orderStatus_screen.dart';
import 'package:preorder/pages/Home/mypage_screen.dart';
import 'package:preorder/pages/Home/home_screen.dart';

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
        return CombinedOrderScreen();
      case 2:
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
        children: List.generate(3, (index) => _buildWidgetOption(index)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
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

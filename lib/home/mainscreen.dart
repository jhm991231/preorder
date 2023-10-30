import 'package:flutter/material.dart';
import '../body/mypage.dart';  // MyPage 위젯을 가져옵니다.
import '../body/home_screen.dart';  // HomeScreen 위젯을 가져옵니다.

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 여기에 화면을 추가합니다.
  final List<Widget> _widgetOptions = [
    HomeScreen(),
    MyPage(),
    // 다른 화면들도 추가 가능
  ];

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
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
          // ... 다른 네비게이션 아이템들
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:preorder/body/order_status.dart';
import '../body/mypage.dart';  // MyPage 위젯을 가져옵니다.
import '../body/home_screen.dart';  // HomeScreen 위젯을 가져옵니다.

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _orderId; // 이 변수는 선택된 주문 ID를 저장합니다.

  // 현재 선택된 인덱스에 따라 위젯을 반환하는 함수
  Widget _buildWidgetOption(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      /*case 1:
      // 여기에서는 OrderStatusPage를 반환하되, orderId는 비동기로 검색해야 합니다.
      // 이 경우, FutureBuilder를 사용하거나 다른 상태 관리 방법을 사용하여
      // orderId를 관리해야 합니다.
      // 아래 코드는 예시이며 실제로는 orderId를 비동기로 가져와야 합니다.
        return _orderId != null
            ? OrderStatusPage(orderId: _orderId!)
            : CircularProgressIndicator();*/
      case 2:
        return MyPage();
    // 다른 화면들도 이와 같이 추가할 수 있습니다.
      default:
        return HomeScreen(); // 기본값으로 홈 화면을 반환합니다.
    }
  }

  @override
  void initState() {
    super.initState();
    // 사용자의 UID를 바탕으로 미완료 주문 ID를 가져옵니다.
    // 여기서 UID는 현재 로그인한 사용자의 UID를 가져와야 합니다.
    String userUid = '사용자의 UID';
    _fetchOrderId(userUid);
  }

  Future<void> _fetchOrderId(String userUid) async {
    _orderId = await OrderService().getUnfinishedOrderDocumentId(userUid);
    // 주문 ID를 가져온 후 UI를 업데이트합니다.
    if (_selectedIndex == 1) {
      setState(() {});
    }
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
      ),      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
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
        onTap: _onItemTapped,
      ),
    );
  }
}

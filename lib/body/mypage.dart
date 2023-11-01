import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../model/appbar.dart';
import 'package:google_sign_in/google_sign_in.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  Future<void> signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      context.go("/login");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("로그아웃 실패 : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          CustomAppBar(title: '마이페이지', centerTitle: true,),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Color(0xFFE7E7E7),
            ),
            child: Row(
              children: [
                Icon(Icons.person, size: 50),
                SizedBox(width: 16),
                Text(user?.email ?? '로그인 정보 없음'), // 사용자 이메일 가져오기
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Text('새소식',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF969393))),
        ),
        ListTile(
          title: Text('공지사항'),
          trailing: Icon(Icons.navigate_next),
          onTap: () {
            // 터치 시 수행될 동작
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Text('주문',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF969393))),
        ),
        ListTile(
          title: Text('주문현황 상세'),
          trailing: Icon(Icons.navigate_next),
          onTap: () {
            // 터치 시 수행될 동작
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Text('알림',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF969393))),
        ),
        ListTile(
          title: Text('푸시알림 설정'),
          trailing: Icon(Icons.navigate_next),
          onTap: () {
            // 터치 시 수행될 동작
          },
        ),
        ListTile(
          title: Text('알림음 설정'),
          trailing: Icon(Icons.navigate_next),
          onTap: () {
            // 터치 시 수행될 동작
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Text('약관 및 정책',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF969393))),
        ),
        ListTile(
          title: Text('이용약관'),
          trailing: Icon(Icons.navigate_next),
          onTap: () {
            // 터치 시 수행될 동작
          },
        ),
        Expanded(
            child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => signOut(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text('로그아웃', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, backgroundColor: Color(0x8CE7E7E7), //
              ),
            ),
          ),
        ))
      ]),
    );
  }
}

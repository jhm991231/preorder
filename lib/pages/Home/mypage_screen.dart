import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:preorder/components/appbar.dart';
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
      appBar: CustomAppBar(
        title: '마이페이지',
        centerTitle: true,
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFFE7E7E7),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, size: 50),
                const SizedBox(width: 16),
                Text(user?.email ?? '로그인 정보 없음'), // 사용자 이메일 가져오기
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Text('새소식',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF969393))),
        ),
        ListTile(
          title: const Text('공지사항'),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            // 터치 시 수행될 동작
          },
        ),
        const Padding(
          padding: EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Text('주문',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF969393))),
        ),
        ListTile(
          title: const Text('주문현황 상세'),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            // 터치 시 수행될 동작
          },
        ),
        const Padding(
          padding: EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Text('알림',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF969393))),
        ),
        ListTile(
          title: const Text('푸시알림 설정'),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            // 터치 시 수행될 동작
          },
        ),
        ListTile(
          title: const Text('알림음 설정'),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            // 터치 시 수행될 동작
          },
        ),
        const Padding(
          padding: EdgeInsets.only(left: 12.0, top: 8.0, bottom: 8.0),
          child: Text('약관 및 정책',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF969393))),
        ),
        ListTile(
          title: const Text('이용약관'),
          trailing: const Icon(Icons.navigate_next),
          onTap: () {
            // 터치 시 수행될 동작
          },
        ),
        Expanded(
            child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => signOut(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: const Color(0x8CE7E7E7),
                shape:
                    const RoundedRectangleBorder(borderRadius: BorderRadius.zero), //
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text('로그아웃',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ))
      ]),
    );
  }
}

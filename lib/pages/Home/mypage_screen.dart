import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:preorder/components/appbar.dart';
import 'package:preorder/components/logout_confirmation_dialog.dart';
import 'package:preorder/components/user_data_fetcher.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
      fetchUserData().then((data) {
        setState(() {
          userData = data;
        });
      });

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
              color: Colors.transparent,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(user?.photoURL ?? ''),
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['name'] ?? '사용자 이름 없음',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        userData['email'] ?? '로그인 정보 없음',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      )
                    ],
                  ),
                )
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
              onPressed: () => showLogoutConfirmation(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: const Color(0x8CE7E7E7),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero), //
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

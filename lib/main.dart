import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:preorder/body/make_order.dart';
import 'package:preorder/firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:preorder/home/mainscreen.dart';
import 'package:preorder/login/login_screen.dart';
import 'package:preorder/body/mypage.dart';

import 'body/cart.dart';
import 'body/home_screen.dart';
import 'login/sign_up_screen.dart';

UserCredential? userCredential;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    try {
      //await FirebaseAuth.instance.useAuthEmulator("localhost", 9099);
      //FirebaseFirestore.instance.useFirestoreEmulator("localhost", 8080);
      //FirebaseStorage.instance.useStorageEmulator("localhost", 9199);
    } catch (e) {
      print(e);
    }
  }

  // 이전 종료시 로그인 상태였는지 로그아웃 상태였는지
  final initialRoute =
      FirebaseAuth.instance.currentUser == null ? "/login" : "/home";

  runApp(PreorderApp(initialRoute: initialRoute));
}

class PreorderApp extends StatelessWidget {
  final String initialRoute;

  PreorderApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {

    String currentUserId= FirebaseAuth.instance.currentUser?.uid ?? '';

    final GoRouter router = GoRouter(
      initialLocation: initialRoute,
      routes: [
        GoRoute(
          path: "/home",
          builder: (context, state) => MainScreen(),
        ),
        GoRoute(
          path: "/login",
          builder: (context, state) => LoginScreen(),
        ),
        GoRoute(
          path: "/sign_up",
          builder: (context, state) => SignUpScreen(),
        ),
        GoRoute(
          path: "/my_page",
          builder: (context, state) => MyPage(),
        ),
        GoRoute(
          path: "/cart",
          builder: (context, state) => CartScreen(userId: currentUserId),
        )
      ],
    );

    return MaterialApp.router(
      title: '도카 PreOrder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

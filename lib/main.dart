import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:preorder/pages/Order/order_screen.dart';
import 'package:preorder/firebase_options.dart';
import 'package:preorder/pages/Home/main_screen.dart';
import 'package:preorder/pages/LogIn/login_screen.dart';
import 'package:preorder/pages/Order/cart_screen.dart';
import 'package:preorder/pages/LogIn/sign_up_screen.dart';

UserCredential? userCredential;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission();
  print('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // 채널 ID
    'High Importance Notifications', // 채널 이름
    description: 'This channel is used for important notifications.', // 채널 설명
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 플러그인 초기화
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

// 포그라운드에서 메시지 수신 처리
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'megaphone'
            // 기타 알림 설정...
          ),
          // iOS와 기타 플랫폼을 위한 설정...
        ),
      );
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
      FirebaseAuth.instance.currentUser == null ? "/login" : "/";

  runApp(PreorderApp(initialRoute: initialRoute));
}

class PreorderApp extends StatelessWidget {
  final String initialRoute;

  PreorderApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final GoRouter router = GoRouter(
      initialLocation: initialRoute,
      routes: [
        GoRoute(
          path: "/",
          builder: (context, state) {
            var index = state.extra as int? ?? 0;
            return MainScreen(key: UniqueKey(), initialIndex: index);
          },
        ),
        GoRoute(
          path: "/login",
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: "/sign_up",
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: "/cart",
          builder: (context, state) => CartScreen(userId: currentUserId),
        ),
        GoRoute(
          path: "/order",
          builder: (context, state) => OrderScreen(userId: currentUserId),
        ),
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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // 채널 ID
    'High Importance Notifications', // 채널 이름
    description: 'This channel is used for important notifications.', // 채널 설명
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // 플러그인 초기화
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 백그라운드에서 수신된 알림을 사용자에게 표시
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  if (notification != null && android != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'megaphone', // 적절한 아이콘 설정 필요
        ),
        // iOS와 기타 플랫폼을 위한 설정...
      ),
    );
  }
}


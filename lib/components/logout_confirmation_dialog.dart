import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

void showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          '로그아웃',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          '로그아웃 하시겠습니까?',
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('아니오'),
              ),
              SizedBox(width: 40,),
              TextButton(
                onPressed: () {
                  signOut(context);
                  Navigator.of(context).pop();
                },
                child: const Text('예'),
              )
            ],
          )
        ],
      );
    },
  );
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController emailTextController = TextEditingController();
  TextEditingController pwdTextController = TextEditingController();
  TextEditingController nameTextController = TextEditingController();

  Future<bool> signUp(String emailAddress, String password, String name) async {
    try {
      // 1. 회원가입
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailAddress, password: password);

      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();

      // 2.user라는 collection에 document 생성해서 저장, 문서ID는 유저의 uid로 세팅
      String userId = credential.user?.uid ?? ""; // 사용자 UID를 얻습니다.
      await FirebaseFirestore.instance.collection("users").doc(userId).set({
        "uid": userId,
        "email": credential.user?.email ?? "",
        "name": name,
      }, SetOptions(merge: true));

      return true;
          } on FirebaseAuthException catch (e) {
      if (e.code == "weak-password") {
      } else if (e.code == "email-already-in-use") {
      }
      return false;
    } catch (e) {
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("회원가입"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(48.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "도서관 카페\n가입을 환영합니다.",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 42,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: emailTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "이메일",
                      ),
                      validator: (value) {
                        // Form state에서 입력하면 validator 함수가 호출
                        if (value == null || value.isEmpty) {
                          return "이메일 주소를 입력하세요";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextFormField(
                      controller: pwdTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "비밀번호",
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "비밀번호를 입력하세요";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextFormField(
                      controller: nameTextController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "이름",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "이름을 입력하세요";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              MaterialButton(
                onPressed: () async {
                  // form check -> 비어있는지 안비어있는지
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    final result = await signUp(
                      emailTextController.text.trim(),
                      pwdTextController.text.trim(),
                      nameTextController.text.trim(),
                    );
                    if (result) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Center(child: Text("회원가입 성공"))),
                        );
                        context.go("/login");
                      }
                    } else {

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Center(child: Text("회원가입 실패"))),
                        );
                      }
                    }
                  }
                },
                height: 48,
                minWidth: double.infinity,
                color: Colors.red,
                child: const Text(
                  "회원가입",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

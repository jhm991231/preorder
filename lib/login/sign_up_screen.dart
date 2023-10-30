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

  Future<bool> signUp(String emailAddress, String password) async {
    try {
      // 1. 회원가입
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailAddress, password: password);
      // 2.user라는 collection에 document 생성해서 저장
      await FirebaseFirestore.instance.collection("users").add({
        "uid": credential.user?.uid ?? "",
        "email": credential.user?.email ?? ""
      });
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == "weak-password") {
        print("패스워드가 약합니다.");
      } else if (e.code == "email-already-in-use") {
        print("이미 정보가 존재합니다.");
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
                      height: 24,
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
                    )
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
                    );
                    if (result) {
                      print("sign-up successful");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("회원가입 성공")),
                        );
                      }

                      context.go("/login");
                    } else {
                      print("sign-up failed");

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("회원가입 실패")),
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

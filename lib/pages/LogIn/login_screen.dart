import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:preorder/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // TextForm 필드에서 컨트롤러로 활용
  TextEditingController emailTextController = TextEditingController();
  TextEditingController pwdTextController = TextEditingController();

  //FCM 토큰 Firestore에 저장하는 함수
  Future<void> saveTokenToFirestore(String? token) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'token': token,
    }, SetOptions(merge: true));
  }

  // 회원가입한 내역을 가지고 로그인 검증
  //firbase에서 인증에서 로그인하는 로직
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if(credential.user!=null){
        String? token=await FirebaseMessaging.instance.getToken();
        await saveTokenToFirestore(token);
      }
      userCredential = credential;

      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
      } else if (e.code == "wrong-password") {
      }
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    // 1. googleauth로 로그인해 accessToken & idToken 받아오기
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // 2. 받아온 2개의 token을 통해 credential을 만든다
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    // 3. signInWithCredential에 credential 넣어 firebase 인증에 정보 등록 가능
    // 즉, gooleAuth를 통해 token들 가져와서 firebase에 넣는다
    UserCredential userCredential= await FirebaseAuth.instance.signInWithCredential(credential);

    // Firestore에 사용자 정보 저장
    User? user = userCredential.user;
    if (user != null) {
      // users 컬렉션에 문서 추가 (문서 ID = 사용자 UID)
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'uid': user.uid,
        'name': user.displayName,
      }, SetOptions(merge: true)); // merge: true 옵션을 사용하여 이미 존재하는 문서에 데이터를 추가하거나 업데이트

      String? token = await FirebaseMessaging.instance.getToken();
      await saveTokenToFirestore(token);
    }

    return userCredential;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/AjouLogo.png"), // --> 상단 로고 넣기
                const SizedBox(
                  height: 24,
                ),
                const Text(
                  "도서관 카페",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 42,
                  ),
                ),
                const SizedBox(
                  height: 30,
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
                        // 비밀번호 누르면 화면에서 안보이게
                        keyboardType: TextInputType.visiblePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "비밀번호를 입력하세요";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: MaterialButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();

                        final result = await signIn(
                            emailTextController.text.trim(),
                            pwdTextController.text.trim());

                        if (result == null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Center(child: Text("로그인 실패")),
                              ),
                            );
                          }
                          return;
                        }
                        // 로그인 및 검증 성공
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Center(child: Text("환영합니다")),
                            ),
                          );
                          context.go("/");
                        }
                      }
                    },
                    height: 48,
                    minWidth: double.infinity,
                    color: Colors.red,
                    child: const Text(
                      "로그인",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push("/sign_up"),
                  child: const Text("계정이 없나요? 회원가입"),
                ),
                const Divider(),
                InkWell(
                    onTap: () async {
                      final userCredit = await signInWithGoogle();

                      if (userCredit == null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Center(child: Text("로그인 실패"))));
                        return;
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Center(child: Text("환영합니다")),
                          ),
                        );
                        context.go("/");
                      }
                    },
                    child: Image.asset("assets/btn_google_signin.png")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, dynamic>> fetchUserData() async {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> userData = {};

  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

  if (userDoc.exists) {
    userData = userDoc.data() as Map<String, dynamic>;
  }

  return userData;
}

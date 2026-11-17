//user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  Future<UserCredential> signIn({
    required String email,
    required String password}){

      return _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    final provider = GoogleAuthProvider();

    final credential = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);

    final user = credential.user!;
    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) {
      await _users.doc(user.uid).set({
        'uid': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
      });
    }
    return credential;
  }

  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password}) async {

    final credential = await
      _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
    final user = credential.user!;

    await _users.doc(user.uid).set({
      'uid' : user.uid,
      'displayName' : name.trim(),
      'email' : email.trim(),
      'photoURL': ''
    });
    return credential;

  }

  Future<UserModel?> getUser() async{
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromSnap(doc);
}
}

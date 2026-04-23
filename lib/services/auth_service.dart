import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<String?> register({
    required String username,
    required String email,
    required String password,
    required String university,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = credential.user!.uid;
      await _db.collection('users').doc(uid).set({
        'username': username.trim(),
        'email': email.trim(),
        'university': university,
        'createdAt': Timestamp.now(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String> getUserUniversity() async {
    final uid = currentUser!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    return doc['university'] ?? '';
  }

  Future<String> getUserName() async {
    final uid = currentUser!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    return doc['username'] ?? '';
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = currentUser!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}

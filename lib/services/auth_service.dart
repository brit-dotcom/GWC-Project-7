import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signUp(String email, String password) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;

    // Create the Firestore user document when a new account is made
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'username': email.split('@')[0], // temp username from email
        'coins': 0,                      // starting coin balance
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return user;
  }

  Future<User?> signIn(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
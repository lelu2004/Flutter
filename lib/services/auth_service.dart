import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Register User
  Future<User?> registerWithEmail(String email, String password, String role, Map<String, dynamic> additionalData) async {
    try {
      UserCredential credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      User? user = credential.user;

      if (user != null) {
        final userData = {
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          ...additionalData,
        };
        await _firestore.collection('users').doc(user.uid).set(userData);
        print('Register: Saved user doc with role $role for UID ${user.uid}');
      }
      return user;
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }


  //Login User
  Future<User?> loginWithEmail(String email, String password) async {
    try{
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Error during login: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  //role based access
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return userDoc.get('role') as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching user role: $e');
      rethrow;
    }
  }

  //Logout User
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  //Auth State Changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> updateStudentProfile({
    required String fullName,
    required String phoneNumber,
    required String university,
    required String major,
    required List<String> skills,
  }) async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception("Chưa đăng nhập người dùng");

      await _firestore.collection('users').doc(uid).update({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'university': university,
        'major': major,
        'skills': skills,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print("Backend: Cập nhật thông tin sinh viên thành công.");
    } catch (e) {
      print("Backend Error - UpdateProfile: $e");
      rethrow;
    }
  }

}
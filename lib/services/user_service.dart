import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Lấy thông tin Profile của sinh viên hiện tại
  Future<Map<String, dynamic>?> getCurrentStudentProfile() async {
    try {
      String? uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Backend Error - GetProfile: $e");
    }
    return null;
  }

  // 2. Cập nhật thông tin chi tiết sinh viên (Yêu cầu số 2)
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

  // 3. Lấy thông tin sinh viên theo ID (Dùng cho trang Công ty)
  Future<Map<String, dynamic>?> getStudentById(String studentId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(studentId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print("Backend Error - GetStudentById: $e");
      return null;
    }
  }
}
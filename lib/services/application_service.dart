import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<int> getApprovedCount(String positionId) async {
    try {
      AggregateQuerySnapshot snapshot = await _firestore
          .collection('applications')
          .where('positionId', isEqualTo:  positionId)
          .where('status', isEqualTo: 'approved')
          .count() // Sử dụng hàm count() của Firebase
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print("Lỗi khi đếm số lượng: $e");
      return 0;
    }
  }

  Future<bool> hasUserApplied(String positionId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;

      final snapshot = await _firestore
          .collection('applications')
          .where('studentId', isEqualTo: uid)
          .where('positionId', isEqualTo: positionId)
          .limit(1) // Chỉ cần tìm thấy 1 bản ghi là đủ
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Lỗi khi kiểm tra đơn trùng: $e");
      return false;
    }
  }

  Future<void> submitApplication({
    required String positionId,
    required String companyId,
    String cvUrl = 'link-cv-gia-lap',
  }) async {
    final studentId = _auth.currentUser?.uid;
    if (studentId == null) throw Exception("Bạn cần đăng nhập để nộp đơn.");

    DocumentSnapshot posDoc = await _firestore.collection('positions').doc(positionId).get();
    if (!posDoc.exists) throw Exception("Vị trí không tồn tại.");
    final posData = posDoc.data() as Map<String, dynamic>;
    int maxSlots = posData['maxSlots'] ?? 10;

    int approvedCount = await getApprovedCount(positionId);

    if (approvedCount >= maxSlots) {
      throw Exception("Vị trí này đã tuyển đủ người.");
    }

    if (await hasUserApplied(positionId)) {
      throw Exception("Bạn đã nộp đơn ứng tuyển cho vị trí này rồi.");
    }
    final checkDuplicate = await _firestore
        .collection('applications')
        .where('studentId', isEqualTo: studentId)
        .where('positionId', isEqualTo: positionId)
        .get();

    if (checkDuplicate.docs.isNotEmpty) {
      throw Exception("Bạn đã nộp đơn ứng tuyển cho vị trí này rồi.");
    }
    await _firestore.collection('applications').add({
      'studentId': studentId,
      'positionId': positionId,
      'companyId': companyId,
      'status': 'submitted',
      'submittedAt': FieldValue.serverTimestamp(),
      'cvUrl': cvUrl,
    });
  }

  // Thêm hàm này vào class ApplicationService trong application_service.dart
  Future<String?> getApplicationStatus(String positionId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final snapshot = await _firestore
          .collection('applications')
          .where('studentId', isEqualTo: uid)
          .where('positionId', isEqualTo: positionId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Trả về trường 'status' thực tế (submitted, approved, rejected, completed)
        return snapshot.docs.first.data()['status'] as String?;
      }
    } catch (e) {
      print("Lỗi lấy trạng thái: $e");
    }
    return null;
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Thêm vào một service mới hoặc CompanyHomePage
  Future<void> completeInternship(String appId) async {
    await FirebaseFirestore.instance
        .collection('applications')
        .doc(appId)
        .update({'status': 'completed'});
  }

  Future<void> submitApplication({
    required String positionId,
    required String companyId,
    String cvUrl = 'link-cv-gia-lap',
  }) async {
    final studentId = _auth.currentUser?.uid;
    if (studentId == null) throw Exception("Bạn cần đăng nhập để nộp đơn.");

    // [QUAN TRỌNG]: Kiểm tra xem sinh viên này đã nộp đơn cho vị trí này chưa
    final checkDuplicate = await _firestore
        .collection('applications')
        .where('studentId', isEqualTo: studentId)
        .where('positionId', isEqualTo: positionId)
        .get();

    if (checkDuplicate.docs.isNotEmpty) {
      throw Exception("Bạn đã nộp đơn ứng tuyển cho vị trí này rồi.");
    }

    // Nếu chưa có, tiến hành lưu đơn mới
    await _firestore.collection('applications').add({
      'studentId': studentId,
      'positionId': positionId,
      'companyId': companyId,
      'status': 'submitted',
      'submittedAt': FieldValue.serverTimestamp(),
      'cvUrl': cvUrl,
    });
  }
}
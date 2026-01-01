import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Của bạn: Hàm xác nhận hoàn thành thực tập
  Future<void> completeInternship(String appId) async {
    await _firestore
        .collection('applications')
        .doc(appId)
        .update({'status': 'completed'});
  }

  // 2. Của bạn: Hàm nộp đơn có kiểm tra trùng lặp (Rất tốt cho Yêu cầu 3)
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

    final approvedApps = await _firestore
        .collection('applications')
        .where('positionId', isEqualTo: positionId)
        .where('status', isEqualTo: 'approved')
        .get();

    if (approvedApps.docs.length >= maxSlots) {
      throw Exception("Vị trí này đã tuyển đủ người.");
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

  // 3. Bổ sung thêm: Truy vấn lịch sử THEO SINH VIÊN (Yêu cầu số 5)
  Stream<QuerySnapshot> getStudentInternshipHistory(String studentId) {
    return _firestore
        .collection('applications')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'completed') // Chỉ lấy kỳ thực tập đã hoàn thành
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  // 4. Bổ sung thêm: Truy vấn lịch sử THEO CHƯƠNG TRÌNH (Dùng cho Admin/Company)
  Stream<QuerySnapshot> getProgramHistory(String companyId) {
    return _firestore
        .collection('applications')
        .where('companyId', isEqualTo: companyId)
        .where('status', isEqualTo: 'completed')
        .snapshots();
  }
}
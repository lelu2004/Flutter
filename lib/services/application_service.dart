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
        .where('status', isEqualTo: 'completed')
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
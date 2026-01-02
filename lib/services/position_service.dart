import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PositionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createPosition({
    required String title,
    required String description,
    required List<String> requirements,
    required DateTime startDate,
    required int maxSlots,

  }) async {
    try {
      String? companyId = _auth.currentUser?.uid;
      if (companyId == null) throw Exception("Chưa đăng nhập");

      final duplicate = await _firestore
          .collection('positions')
          .where('companyId', isEqualTo: companyId)
          .where('title', isEqualTo: title)
          .where('isActive', isEqualTo: true)
          .get();

      if (duplicate.docs.isNotEmpty) {
        throw Exception("Bạn đã đăng tuyển vị trí này rồi. Hãy cập nhật vị trí cũ nếu cần.");
      }

      // 2. Nếu không trùng thì mới tạo
      Map<String, dynamic> positionData = {
        'companyId': companyId,
        'title': title,
        'description': description,
        'requirements': requirements,
        'startDate': Timestamp.fromDate(startDate),
        'maxSlots': maxSlots, // Lưu số lượng tối đa
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('positions').add(positionData);
    } catch (e) {
      rethrow;
    }
  }
  Future<void> updatePosition(String docId, Map<String, dynamic> updatedData)
  async {
    try {
      await _firestore.collection('positions').doc(docId).update(updatedData);
    } catch (e) {
      print("Backend Error - UpdatePosition: $e");
      rethrow;
    }
  }

  // 2. Đóng/Mở vị trí thực tập (Soft Delete)
  Future<void> togglePositionStatus(String docId, bool isActive) async {
    try {
      await _firestore.collection('positions').doc(docId).update({
        'isActive': isActive,
      });
    } catch (e) {
      print("Backend Error - ToggleStatus: $e");
      rethrow;
    }
  }

  // Hàm lấy danh sách vị trí của riêng công ty đó (để quản lý)
  Stream<QuerySnapshot> getCompanyPositions() {
    String companyId = _auth.currentUser?.uid ?? '';
    return _firestore
        .collection('positions')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  }
}
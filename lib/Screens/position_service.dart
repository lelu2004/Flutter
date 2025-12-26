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
  }) async {
    try {
      String? companyId = _auth.currentUser?.uid;

      if (companyId == null) {
        throw Exception("Người dùng chưa đăng nhập hoặc không có quyền.");
      }

      Map<String, dynamic> positionData = {
        'companyId': companyId,
        'title': title,
        'description': description,
        'requirements': requirements,
        'startDate': Timestamp.fromDate(startDate),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('positions').add(positionData);

      print("Backend: Đã tạo vị trí thực tập thành công.");
    } catch (e) {
      print("Backend Error - CreatePosition: $e");
      rethrow;
    }
  }
  Future<void> updatePosition(String docId, Map<String, dynamic> updatedData) async {
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
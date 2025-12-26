import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ Sinh Viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final bool? confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xác nhận đăng xuất'),
                  content: const Text('Bạn có chắc muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Danh sách vị trí thực tập khả dụng', style: TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('positions')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Lỗi tải vị trí'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final positions = snapshot.data!.docs;
                if (positions.isEmpty) return const Center(child: Text('Chưa có vị trí nào khả dụng'));

                return ListView.builder(
                  itemCount: positions.length,
                  itemBuilder: (context, index) {
                    final data = positions[index].data() as Map<String, dynamic>;
                    final positionId = positions[index].id;
                    final companyId = data['companyId']; // Đảm bảo lấy companyId từ positions

                    return ListTile(
                      title: Text(data['title'] ?? 'Vị trí không tên'),
                      subtitle: Text(data['description'] ?? ''),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            print("Backend: Bắt đầu xử lý nộp/cập nhật đơn cho Position: $positionId");

                            // 1. Truy vấn tìm đơn cũ của sinh viên này cho vị trí này
                            final existingApp = await FirebaseFirestore.instance
                                .collection('applications')
                                .where('studentId', isEqualTo: userId)
                                .where('positionId', isEqualTo: positionId)
                                .get();

                            if (existingApp.docs.isNotEmpty) {
                              // TRƯỜNG HỢP 1: Đã có đơn -> Tiến hành CẬP NHẬT thời gian
                              String docId = existingApp.docs.first.id;
                              print("Backend: Đã tìm thấy đơn cũ (ID: $docId). Đang cập nhật thời gian mới...");

                              await FirebaseFirestore.instance
                                  .collection('applications')
                                  .doc(docId)
                                  .update({
                                'submittedAt': FieldValue.serverTimestamp(), // Cập nhật mốc thời gian mới nhất từ server
                                'status': 'submitted', // Reset lại trạng thái nếu cần
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã cập nhật lại thời gian nộp đơn mới nhất!'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            } else {
                              // TRƯỜNG HỢP 2: Chưa có đơn -> Tạo MỚI hoàn toàn
                              print("Backend: Chưa có đơn cũ. Đang tạo đơn mới...");
                              await FirebaseFirestore.instance.collection('applications').add({
                                'studentId': userId,
                                'positionId': positionId,
                                'companyId': companyId,
                                'status': 'submitted',
                                'submittedAt': FieldValue.serverTimestamp(),
                                'cvUrl': 'link-cv-gia-lap'
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nộp đơn lần đầu thành công!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                            print("Backend: Thao tác dữ liệu hoàn tất.");
                          } catch (e) {
                            print('Backend Error: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi hệ thống: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: const Text('Nộp đơn'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Lịch sử đơn ứng tuyển của bạn', style: TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('applications')
                  .where('studentId', isEqualTo: userId)
                  .orderBy('submittedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Lỗi tải lịch sử'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final apps = snapshot.data!.docs;
                if (apps.isEmpty) return const Center(child: Text('Chưa có đơn nào'));

                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final data = apps[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text('Vị trí ID: ${data['positionId']}'),
                      subtitle: Text('Trạng thái: ${data['status']}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_firebase_app/Screens/user_service.dart';
import 'package:my_firebase_app/Screens/application_service.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  // Hàm lấy tiêu đề vị trí từ ID
  Future<String> _getPositionTitle(String positionId) async {
    try {
      var doc = await FirebaseFirestore.instance.collection('positions').doc(positionId).get();
      return doc.exists ? (doc.data() as Map)['title'] ?? 'Vị trí không tên' : 'Vị trí đã đóng';
    } catch (e) {
      return 'Lỗi tải dữ liệu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userService = UserService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ Sinh Viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN 1: CẬP NHẬT THÔNG TIN (Backend Test) ---
            _buildBackendTestSection(context, userService),

            // --- PHẦN 2: DANH SÁCH VỊ TRÍ ---
            const _SectionHeader(title: 'Vị trí thực tập khả dụng'),
            _buildAvailablePositions(userId),

            const Divider(height: 30),

            // --- PHẦN 3: ĐƠN ĐANG XỬ LÝ ---
            const _SectionHeader(title: 'Đơn đang xin thực tập'),
            _buildActiveApplications(userId),

            const Divider(height: 30, thickness: 2, color: Colors.blue),

            // --- PHẦN 4: LỊCH SỬ THỰC TẬP (Yêu cầu 5) ---
            const _SectionHeader(title: '⭐ THÀNH TÍCH THỰC TẬP (Lịch sử)'),
            _buildCompletedHistory(userId),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị lịch sử các kỳ thực tập đã hoàn thành
  Widget _buildCompletedHistory(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final history = snapshot.data!.docs;
        if (history.isEmpty) return const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Text('Bạn chưa có kỳ thực tập nào hoàn thành.'),
        );

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final data = history[index].data() as Map<String, dynamic>;
            return Card(
              color: Colors.green.shade50,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: FutureBuilder<String>(
                  future: _getPositionTitle(data['positionId']),
                  builder: (context, res) => Text(res.data ?? '...', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                subtitle: Text('Đã hoàn thành: ${data['submittedAt']?.toDate().toString().split(' ')[0]}'),
                trailing: const Text('COMPLETED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  // Widget hiển thị đơn đang trong quá trình xử lý
  Widget _buildActiveApplications(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('studentId', isEqualTo: userId)
          .where('status', isNotEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Cần tạo Index trên Firebase Console'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final apps = snapshot.data!.docs;
        if (apps.isEmpty) return const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Text('Không có đơn nào đang chờ xử lý.'),
        );

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final data = apps[index].data() as Map<String, dynamic>;
            return ListTile(
              title: FutureBuilder<String>(
                future: _getPositionTitle(data['positionId']),
                builder: (context, res) => Text('Vị trí: ${res.data ?? "..."}'),
              ),
              subtitle: Text('Trạng thái hiện tại: ${data['status']}'),
            );
          },
        );
      },
    );
  }

  Widget _buildAvailablePositions(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('positions').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final pos = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pos.length,
          itemBuilder: (context, index) {
            final data = pos[index].data() as Map<String, dynamic>;
            final positionId = pos[index].id;
            final companyId = data['companyId'];

            return ListTile(
              title: Text(data['title'] ?? 'Vị trí không tên'),
              subtitle: Text(data['description'] ?? ''),
              trailing: ElevatedButton(
                onPressed: () async {
                  try {
                    await ApplicationService().submitApplication(
                      positionId: positionId,
                      companyId: companyId,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nộp đơn thành công!'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Nộp đơn'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBackendTestSection(BuildContext context, UserService service) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('Cập nhật thông tin (Backend Test)', style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () async {
                  await service.updateStudentProfile(
                    fullName: "Nguyen Le Lu", phoneNumber: "0987654321",
                    university: "Hutech", major: "Software Engineering", skills: ["Flutter", "Dart"],
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
                },
                child: const Text('Gửi dữ liệu mẫu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
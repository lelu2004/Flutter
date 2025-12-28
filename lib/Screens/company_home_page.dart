import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_firebase_app/Screens/position_service.dart';

class CompanyHomePage extends StatelessWidget {
  const CompanyHomePage({super.key});

  // Hàm lấy tên sinh viên từ UID
  Future<String> _getStudentName(String uid) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['fullName'] ?? 'Không rõ tên';
      }
    } catch (e) {
      print('Lỗi lấy tên sinh viên: $e');
    }
    return 'Lỗi tải tên';
  }

  // Hàm lấy tiêu đề vị trí thực tập từ positionId
  Future<String> _getPositionTitle(String positionId) async {
    try {
      DocumentSnapshot posDoc = await FirebaseFirestore.instance
          .collection('positions')
          .doc(positionId)
          .get();
      if (posDoc.exists) {
        final data = posDoc.data() as Map<String, dynamic>;
        return data['title'] ?? 'Vị trí không tên';
      }
    } catch (e) {
      print('Lỗi lấy tiêu đề vị trí: $e');
    }
    return 'ID: $positionId';
  }

  @override
  Widget build(BuildContext context) {
    final companyId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ Công Ty'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Danh sách đơn ứng tuyển', style: TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('applications')
                  .where('companyId', isEqualTo: companyId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Lỗi tải dữ liệu'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final apps = snapshot.data!.docs;
                if (apps.isEmpty) {
                  return const Center(child: Text('Chưa có đơn ứng tuyển nào'));
                }

                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final data = apps[index].data() as Map<String, dynamic>;
                    final studentId = data['studentId'] ?? '';
                    final positionId = data['positionId'] ?? '';
                    final status = data['status'] ?? 'submitted'; // Lấy trạng thái hiện tại

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: FutureBuilder<String>(
                          future: _getStudentName(studentId),
                          builder: (context, nameSnapshot) {
                            if (nameSnapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Đang tải tên...');
                            }
                            return Text(
                              'Sinh viên: ${nameSnapshot.data}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future: _getPositionTitle(positionId),
                              builder: (context, titleSnapshot) {
                                if (titleSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('Vị trí: Đang tải...');
                                }
                                return Text('Vị trí: ${titleSnapshot.data}');
                              },
                            ),
                            Text('Trạng thái: $status'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Nếu đang chờ duyệt (submitted) -> Hiện nút V và X
                            if (status == 'submitted') ...[
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                tooltip: 'Chấp nhận',
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('applications')
                                      .doc(apps[index].id)
                                      .update({'status': 'approved'});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                tooltip: 'Từ chối',
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('applications')
                                      .doc(apps[index].id)
                                      .update({'status': 'rejected'});
                                },
                              ),
                            ],

                            // 2. Nếu đã duyệt (approved) -> Hiện nút Hoàn thành
                            if (status == 'approved')
                              IconButton(
                                icon: const Icon(Icons.assignment_turned_in, color: Colors.blue),
                                tooltip: 'Xác nhận hoàn thành',
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('applications')
                                      .doc(apps[index].id)
                                      .update({'status': 'completed'});
                                },
                              ),

                            // 3. Nếu đã hoàn thành (completed) -> Hiện icon tích xanh
                            if (status == 'completed')
                              const Icon(Icons.verified, color: Colors.blue),

                            // 4. Nếu bị từ chối (rejected) -> Hiện icon chặn
                            if (status == 'rejected')
                              const Icon(Icons.block, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await PositionService().createPosition(
                      title: "Intern Firebase Developer",
                      description: "Thực tập phát triển ứng dụng di động",
                      requirements: ["Dart", "Flutter", "Firebase"],
                      startDate: DateTime.now()
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tạo vị trí thực tập mẫu thành công!')),
                  );
                } catch (e) {
                  print("Lỗi: $e");
                }
              },
              child: const Text('Tạo vị trí mới'),
            ),
          ),
        ],
      ),
    );
  }
}
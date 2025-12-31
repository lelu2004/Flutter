import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 Tab: Vị trí thực tập & Quản lý sinh viên
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản Trị Hệ Thống'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Vị trí thực tập', icon: Icon(Icons.business_center)),
              Tab(text: 'Quản lý sinh viên', icon: Icon(Icons.person_search)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async => await FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildPositionsTab(), // Quản lý chương trình hiện có
            _buildStudentsTab(),  // Quản lý hồ sơ sinh viên
          ],
        ),
      ),
    );
  }

  // TAB 1: Quản lý các vị trí thực tập (Như cũ nhưng có UI gọn hơn)
  Widget _buildPositionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('positions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final companyId = data['companyId'] ?? ''; // Lấy dãy số ID hiện tại

            return ListTile(
              title: Text(data['title'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
              // Thay đổi subtitle ở đây
              subtitle: FutureBuilder<String>(
                future: _getCompanyName(companyId), // Gọi hàm tra cứu tên
                builder: (context, nameSnapshot) {
                  if (nameSnapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Công ty: Đang tải...');
                  }
                  return Text('Công ty: ${nameSnapshot.data}');
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => FirebaseFirestore.instance.collection('positions').doc(docs[index].id).delete(),
              ),
            );
          },
        );
      },
    );
  }
  // Thêm hàm này vào trong class AdminHomePage
  Future<String> _getCompanyName(String uid) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        // Trả về companyName nếu có, nếu không thì trả về fullName hoặc 'Công ty không rõ'
        return data['companyName'] ?? data['fullName'] ?? 'Công ty không rõ';
      }
    } catch (e) {
      print('Lỗi lấy tên công ty: $e');
    }
    return 'Lỗi tải tên';
  }

  // TAB 2: Quản lý danh sách Sinh viên (MỚI)
  Widget _buildStudentsTab() {
    return StreamBuilder<QuerySnapshot>(
      // Truy vấn những người dùng có role là 'student'
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final students = snapshot.data!.docs;

        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final data = students[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(data['fullName'] ?? 'Chưa có tên'),
                subtitle: Text('Trường: ${data['university'] ?? 'N/A'}\nEmail: ${data['email']}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove, color: Colors.redAccent),
                  onPressed: () {
                    // Xóa thông tin sinh viên khỏi database
                    FirebaseFirestore.instance.collection('users').doc(students[index].id).delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
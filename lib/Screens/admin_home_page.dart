import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang Chủ Quản Trị'),
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
            child: Text('Danh sách tất cả chương trình thực tập', style: TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('positions').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text('Lỗi tải dữ liệu');
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final programs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final data = programs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['title'] ?? 'Chương trình không tên'),
                      subtitle: Text('Công ty: ${data['companyId']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          // TODO: Xóa program (chỉ admin)
                          FirebaseFirestore.instance.collection('internshipPrograms').doc(programs[index].id).delete();
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Thêm phần manage users, applications tương tự
        ],
      ),
    );
  }
}
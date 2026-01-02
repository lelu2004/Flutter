import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Future<String> _getNameFromUid(String uid) async {
    if (uid.isEmpty) return 'Không xác định';
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['role'] == 'company' && data['companyName'] != null) {
          return data['companyName']; // Kết quả sẽ là "SamSung"
        }
        return data['fullName'] ?? 'Chưa cập nhật tên';
      }
    } catch (e) {
      debugPrint("Lỗi lấy tên: $e");
    }
    return 'ID: $uid'; // Trả về ID nếu không tìm thấy dữ liệu
  }

  Future<String> _getPositionTitle(String positionId) async {
    if (positionId.isEmpty) return 'Vị trí không rõ';
    try {
      final doc = await FirebaseFirestore.instance.collection('positions').doc(positionId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['title'] ?? 'Không có tiêu đề';
      }
    } catch (e) {
      debugPrint("Lỗi lấy tiêu đề: $e");
    }
    return 'ID: $positionId';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getFullName(Map<String, dynamic> data) {
    return data['fullName'] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Positions'),
            Tab(text: 'Applications'),
            Tab(text: 'Students'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPositionsTab(),
          _buildApplicationsTab(),
          _buildStudentsTab(),
        ],
      ),
    );
  }

  //Positions
  Widget _buildPositionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('positions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No positions'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(data['title'] ?? 'No title'),
                subtitle: FutureBuilder<String>(
                  future: _getNameFromUid(data['companyId'] ?? ''),
                  builder: (context, res) => Text('Công ty: ${res.data ?? "Đang tải..."}'),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await doc.reference.delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  //Application
  Widget _buildApplicationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('applications').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No applications'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: FutureBuilder<String>(
                  future: _getNameFromUid(data['studentId'] ?? ''),
                  builder: (context, res) => Text(
                    'Sinh viên: ${res.data ?? "Đang tải..."}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                subtitle: FutureBuilder<String>(
                  future: _getPositionTitle(data['positionId'] ?? ''),
                  builder: (context, res) => Text(
                    'Vị trí: ${res.data ?? "..."}\nTrạng thái: ${data['status']}',
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await doc.reference.delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  //Students
  Widget _buildStudentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No students'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text(_getFullName(data)),
                subtitle: Text(data['email'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await doc.reference.delete();
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
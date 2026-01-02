import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_firebase_app/services/position_service.dart';

class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({super.key});

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  String selectedTab = 'submitted';

  void _showCreatePositionDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final slotsController = TextEditingController(text: '1'); // Mặc định tuyển 1 người

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng Tuyển Vị Trí Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tiêu đề (Vd: Intern Flutter)')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả công việc')),
              TextField(
                controller: slotsController,
                decoration: const InputDecoration(labelText: 'Số lượng cần tuyển (Slots)'),
                keyboardType: TextInputType.number, // Chỉ cho nhập số
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              try {
                int slots = int.tryParse(slotsController.text) ?? 1;
                await PositionService().createPosition(
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  requirements: ['Flutter', 'Firebase'], // Có thể mở rộng thêm field nhập list
                  startDate: DateTime.now(),
                  maxSlots: slots, // Truyền giá trị từ người dùng nhập
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo vị trí thành công!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Đăng tuyển'),
          ),
        ],
      ),
    );
  }

  // ================= GET STUDENT NAME (FIXED) =================
  Future<String> _getStudentName(String uid) async {
    try {
      // 1️⃣ Try Firestore
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data['fullName'] != null && data['fullName'].toString().isNotEmpty) {
          return data['fullName'];
        }
      }

      // 2️⃣ Fallback to Firebase Auth displayName
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null &&
          authUser.uid == uid &&
          authUser.displayName != null) {
        return authUser.displayName!;
      }
    } catch (e) {
      debugPrint('Error getting student name: $e');
    }

    // 3️⃣ Final fallback
    return 'Unknown';
  }

  // ================= GET POSITION TITLE =================
  Future<String> _getPositionTitle(String positionId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('positions')
          .doc(positionId)
          .get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['title'] ?? 'No title';
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return 'Position closed';
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
            onPressed: () async => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // ================= TABS =================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Pending'),
                selected: selectedTab == 'submitted',
                onSelected: (_) =>
                    setState(() => selectedTab = 'submitted'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('History'),
                selected: selectedTab == 'history',
                onSelected: (_) =>
                    setState(() => selectedTab = 'history'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ================= APPLICATION LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedTab == 'submitted'
                  ? FirebaseFirestore.instance
                  .collection('applications')
                  .where('companyId', isEqualTo: companyId)
                  .where('status', isEqualTo: 'submitted')
                  .snapshots()
                  : FirebaseFirestore.instance
                  .collection('applications')
                  .where('companyId', isEqualTo: companyId)
                  .where(
                'status',
                whereIn: ['approved', 'rejected', 'completed'],
              )
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final apps = snapshot.data!.docs;

                if (apps.isEmpty) {
                  return const Center(child: Text('No applications'));
                }

                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    final data = app.data() as Map<String, dynamic>;

                    final studentId = data['studentId'];
                    final positionId = data['positionId'];
                    final status = data['status'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: FutureBuilder<String>(
                          future: _getStudentName(studentId),
                          builder: (context, snapshot) => Text(
                            'Sinh viên: ${snapshot.data ?? 'Loading...'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future: _getPositionTitle(positionId),
                              builder: (context, snapshot) => Text(
                                  'Vị trí: ${snapshot.data ?? '...'}'),
                            ),
                            Text('Trạng thái: $status'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ===== PENDING =====
                            if (status == 'submitted') ...[
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () {
                                  app.reference
                                      .update({'status': 'approved'});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.red),
                                onPressed: () {
                                  app.reference
                                      .update({'status': 'rejected'});
                                },
                              ),
                            ],

                            // ===== APPROVED → COMPLETED =====
                            if (status == 'approved')
                              IconButton(
                                icon: const Icon(
                                    Icons.assignment_turned_in,
                                    color: Colors.blue),
                                onPressed: () {
                                  app.reference
                                      .update({'status': 'completed'});
                                },
                              ),

                            // ===== STATUS ICONS =====
                            if (status == 'completed')
                              const Icon(Icons.verified,
                                  color: Colors.blue),
                            if (status == 'rejected')
                              const Icon(Icons.block,
                                  color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ================= CREATE POSITION =================
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showCreatePositionDialog, // Gọi hàm mở Form
              icon: const Icon(Icons.add),
              label: const Text('Đăng vị trí thực tập mới'),
            ),
          ),
        ],
      ),
    );
  }
}

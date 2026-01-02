import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_firebase_app/services/application_service.dart';
import 'package:my_firebase_app/services/user_service.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController majorController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController universityController = TextEditingController();
  final User user = FirebaseAuth.instance.currentUser!;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // ================= LOAD USER DATA =================
  Future<void> _loadUserProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['fullName'] ?? '';
      majorController.text = data['major'] ?? '';
      universityController.text = data['university'] ?? '';
      phoneController.text = data['phoneNumber'] ?? '';
    }
  }

  // ================= SAVE USER DATA =================
  Future<void> _saveProfile() async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        universityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ Họ tên, Số điện thoại và Trường học!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await UserService().updateStudentProfile(
        fullName: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        university: universityController.text.trim(),
        major: majorController.text.trim(),
        skills: ["Flutter", "Dart"], // Có thể mở rộng thêm phần nhập skills sau
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hồ sơ đã được cập nhật chuẩn xác!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _applyForPosition(String posId, String compId) async {
    try {
      await ApplicationService().submitApplication(
        positionId: posId,
        companyId: compId,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nộp đơn thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.orange),
      );
    }
  }
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved': return Colors.greenAccent;
      case 'rejected': return Colors.redAccent;
      case 'submitted': return Colors.orangeAccent;
      case 'completed': return Colors.blueAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cổng Thông Tin Sinh Viên'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // THIẾT KẾ LẠI PHẦN PROFILE
          _buildProfileSection(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          const Text("Vị trí thực tập khả dụng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildAvailablePositions(),

          const SizedBox(height: 24),
          const Text("Trạng thái ứng tuyển", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildActiveApplications(),
        ]),
      ),
    );
  }

  // ================= APPLICATION STATUS =================
  Widget _buildProfileSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          const Row(children: [
            Icon(Icons.person_pin, color: Colors.blue),
            SizedBox(width: 8),
            Text("Thông tin cá nhân", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Họ và Tên')),
          TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Số điện thoại')),
          TextField(controller: universityController, decoration: const InputDecoration(labelText: 'Trường Đại học')),
          TextField(controller: majorController, decoration: const InputDecoration(labelText: 'Chuyên ngành')),
          const SizedBox(height: 16),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save),
            label: const Text("Cập nhật hồ sơ"),
          ),
        ]),
      ),
    );
  }

  // ================= AVAILABLE POSITIONS =================
  Widget _buildAvailablePositions() {
    final ApplicationService _appService = ApplicationService();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('positions')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final positions = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: positions.length,
          itemBuilder: (context, index) {
            final data = positions[index].data() as Map<String, dynamic>;
            final positionId = positions[index].id;
            final companyId = data['companyId'];

            return FutureBuilder<List<dynamic>>(
              future: Future.wait([
                _appService.getApprovedCount(positionId),
                _appService.getApplicationStatus(positionId), // Gọi hàm lấy trạng thái thực tế
              ]),
              builder: (context, futureSnapshot) {
                if (!futureSnapshot.hasData) return const SizedBox(height: 80);

                final int approvedCount = futureSnapshot.data![0];
                final String? currentStatus = futureSnapshot.data![1]; // Lấy status ở đây
                final int maxSlots = data['maxSlots'] ?? 10;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(data['title'] ?? 'No title', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Đã tuyển: $approvedCount/$maxSlots"),

                    // LOGIC HIỂN THỊ THEO TRẠNG THÁI THỰC TẾ
                    trailing: currentStatus != null
                        ? _buildStatusChip(currentStatus) // Hàm phụ để vẽ nhãn màu sắc
                        : (approvedCount >= maxSlots
                        ? const Text("HẾT CHỖ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                        : ElevatedButton(
                      child: const Text('Apply'),
                      onPressed: () => _applyForPosition(positionId, companyId),
                    )),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

// Hàm phụ để tạo nhãn trạng thái đẹp mắt
  Widget _buildStatusChip(String status) {
    String label = "ĐÃ NỘP";
    Color color = Colors.orangeAccent;

    switch (status.toLowerCase()) {
      case 'approved':
        label = "ĐÃ ĐƯỢC DUYỆT";
        color = Colors.green;
        break;
      case 'rejected':
        label = "BỊ TỪ CHỐI";
        color = Colors.redAccent;
        break;
      case 'completed':
        label = "HOÀN THÀNH";
        color = Colors.blue;
        break;
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
      backgroundColor: color,
    );
  }
  Widget _buildActiveApplications() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('applications').where('studentId', isEqualTo: user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final apps = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: apps.length,
          itemBuilder: (context, index) {
            final data = apps[index].data() as Map<String, dynamic>;
            return Card(
              color: Colors.grey[50],
              child: ListTile(
                title: Text('Vị trí ID: ${data['positionId']}'),
                trailing: Chip(
                  label: Text(data['status'].toString().toUpperCase()),
                  backgroundColor: _getStatusColor(data['status']),
                ),
              ),
            );
          },
        );
      },
    );

  }
}

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

  // ================= POSITIONS =================
  Widget _buildPositionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('positions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No positions'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                title: Text(data['title'] ?? 'No title'),
                subtitle: Text('Company ID: ${data['companyId']}'),
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

  // ================= APPLICATIONS =================
  Widget _buildApplicationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('applications').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No applications'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                title: Text('Student: ${data['studentId']}'),
                subtitle: Text(
                  'Position: ${data['positionId']}\nStatus: ${data['status']}',
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

  // ================= STUDENTS =================
  Widget _buildStudentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No students'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                title: Text(data['fullName'] ?? ''),
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

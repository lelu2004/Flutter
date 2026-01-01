import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'Screens/login_screen.dart';
import 'Screens/user_home_page.dart';
import 'Screens/company_home_page.dart';
import 'Screens/admin_home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Bắt buộc
  await Firebase.initializeApp(); // Bắt buộc để dùng Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();
  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Internship Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting){
            return const CircularProgressIndicator();
          }
          if(snapshot.hasData){
            // User is logged in
            return FutureBuilder<String?>(
            future: _authService.getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if(roleSnapshot.connectionState == ConnectionState.waiting){
                return const CircularProgressIndicator();
              }
                final String? role = roleSnapshot.data;
                if (role == 'admin') {
                  return const AdminHomePage();
                } else if (role == 'company') {
                  return const CompanyHomePage();
                } else if (role == 'student') {
                  return const UserHomePage();
                } else {
                  return const LoginScreen();
                }
              },
            );
          }
          return LoginScreen();
        },
      ),
    );
  }
}


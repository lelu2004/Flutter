import 'package:flutter/material.dart';
import 'package:my_firebase_app/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _extraController = TextEditingController();  // Field tùy role, ví dụ university hoặc companyName
  String? _selectedRole;
  String? _errorMessage;

  Future<void> _register() async {
    if (_selectedRole == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn vai trò';
      });
      return;
    }

    Map<String, dynamic> additionalData = {
      'fullName': _fullNameController.text,
    };

    // Thêm field tùy role
    if (_selectedRole == 'student') {
      additionalData['university'] = _extraController.text;
    } else if (_selectedRole == 'company') {
      additionalData['companyName'] = _extraController.text;
    }  // Admin không cần extra

    try {
      await _authService.registerWithEmail(
        _emailController.text,
        _passwordController.text,
        _selectedRole!,
        additionalData,
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _errorMessage = 'Đăng ký thất bại: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Ký')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Họ và Tên'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              hint: const Text('Chọn vai trò'),
              value: _selectedRole,
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Sinh viên')),
                DropdownMenuItem(value: 'company', child: Text('Công ty')),
                DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedRole == 'student')
              TextField(
                controller: _extraController,
                decoration: const InputDecoration(labelText: 'Trường đại học'),
              ),
            if (_selectedRole == 'company')
              TextField(
                controller: _extraController,
                decoration: const InputDecoration(labelText: 'Tên công ty'),
              ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Đăng Ký'),
            ),
          ],
        ),
      ),
    );
  }
}
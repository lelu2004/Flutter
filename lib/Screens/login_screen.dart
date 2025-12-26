import 'package:flutter/material.dart';
import 'package:my_firebase_app/services/auth_service.dart';
import 'package:my_firebase_app/Screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override 
  _LoginScreenState createState() => _LoginScreenState();
  
}
class _LoginScreenState extends State<LoginScreen>{
  final AuthService _authService = AuthService(); 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  Future<void> _login() async {
    try {
      await _authService.loginWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      // Navigate to home screen on successful login
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please check your credentials.';
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            TextButton(onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                );
            },
            child: const Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}  
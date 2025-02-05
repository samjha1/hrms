import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hr_app/homepage.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _username = '';

  // Open the Hive box to store user data
  Box? userBox;

  @override
  void initState() {
    super.initState();
    _openHiveBox();
  }

  // Open the Hive box to store user data
  Future<void> _openHiveBox() async {
    userBox = await Hive.openBox('user');

    // Retrieve user data after box is opened
    String? userData = userBox?.get('user');
    if (userData != null) {
      var decodedData = jsonDecode(userData);

      // Set the username or other fields
      setState(() {
        _username = decodedData['username'] ?? 'Unknown';
      });
    } else {
      print("No user data found in Hive");
    }
  }

  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showToast("Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://landlink.in/login_api.php'),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Decoded data: $data'); // Debug print

        if (data['status'] == 'success' && data['user'] != null) {
          // Store user data in Hive
          var box = await Hive.openBox('userBox');

          // Store the entire user object
          await box.put('userData', jsonEncode(data['user']));
          print('Stored user data: ${box.get('userData')}'); // Debug print

          // Redirect based on role
          _redirectUser(data['user']['role']);
        } else {
          _showToast(data['message'] ?? 'Login failed');
        }
      } else {
        _showToast('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e'); // Debug print
      _showToast('Connection error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _redirectUser(String role) {
    final routes = {
      'admin': AdminDashboard(),
      'user': HRDashboard(),
      'manager': ManagerDashboard(),
      'hr': FrontPage(),
    };

    final route = routes[role.toLowerCase()];
    if (route != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => route),
      );
    } else {
      _showToast('Unknown user role: $role');
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red[700],
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blueAccent, Colors.purpleAccent],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _LoginHeader(),
                const SizedBox(height: 40),
                _LoginCard(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isLoading: _isLoading,
                  onLogin: _loginUser,
                ),
                const SizedBox(height: 20),
                Text('Welcome back, $_username',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Sign in to continue',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onLogin;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: _inputDecoration('Email', Icons.email),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: _inputDecoration('Password', Icons.lock),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blueAccent,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: const Center(child: Text("Welcome to Admin Dashboard")),
    );
  }
}

class UserDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Dashboard")),
      body: const Center(child: Text("Welcome to User Dashboard")),
    );
  }
}

class ManagerDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manager Dashboard")),
      body: const Center(child: Text("Welcome to Manager Dashboard")),
    );
  }
}

class FrontPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Front Page")),
      body: const Center(child: Text("Welcome to the Front Page")),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:OrangeScoutFE/view/loginScreen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:OrangeScoutFE/controller/authController.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'RegisterScreen',
        screenClass: 'RegisterScreenState',
      );
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
      }
      FirebaseAnalytics.instance.logEvent(
        name: 'register_attempt',
        parameters: {
          'status': 'failed',
          'reason': 'empty_fields',
          'username_provided': username.isNotEmpty,
          'email_provided': email.isNotEmpty,
          'password_provided': password.isNotEmpty,
        },
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final RegisterResult result = await _authController.registerUser(username, email, password);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! You can now log in.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        FirebaseAnalytics.instance.logEvent(
          name: 'register_attempt',
          parameters: {
            'status': 'success',
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Unknown registration error')),
        );
        FirebaseAnalytics.instance.logEvent(
          name: 'register_attempt',
          parameters: {
            'status': 'failed',
            'reason': result.errorMessage ?? 'unknown_reason',
          },
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget customButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF9800),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final contentHeight = screenHeight - keyboardSpace;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFFFF4500),
              Color(0xFF84442E),
              Color(0xFF3A2E2E),
            ],
            stops: [0.0, 0.2, 0.7],
          ),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: keyboardSpace),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: contentHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/OrangeScoutLogo.png',
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: MediaQuery.of(context).size.width * 0.5 * (250 / 410),
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 15),

                  // Campo de Username
                  SizedBox(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF57C00).withOpacity(0.7),
                        hintText: "Username",
                        hintStyle: const TextStyle(color: Color(0xFFFFCC80)),
                        labelText: "Username",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFFFFCC80)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Campo de Email
                  SizedBox(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF57C00).withOpacity(0.7),
                        hintText: "Email",
                        hintStyle: const TextStyle(color: Color(0xFFFFCC80)),
                        labelText: "Email Address",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.email, color: Color(0xFFFFCC80)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Campo de Senha
                  SizedBox(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF57C00).withOpacity(0.7),
                        hintText: "Password",
                        hintStyle: const TextStyle(color: Color(0xFFFFCC80)),
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFCC80)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  customButton(
                    text: "Register",
                    isLoading: _isLoading,
                    onPressed: _isLoading ? () {} : _register,
                  ),
                  const SizedBox(height: 25),
                  GestureDetector(
                    onTap: () {
                      FirebaseAnalytics.instance.logEvent(
                        name: 'navigate_to_login_clicked',
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: const Text(
                      "I already have an account",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

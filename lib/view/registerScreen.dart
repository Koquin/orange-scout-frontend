import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:OrangeScoutFE/controller/auth_controller.dart';
import 'package:OrangeScoutFE/view/loginScreen.dart';
import 'package:OrangeScoutFE/util/persistent_snackbar.dart';

import '../dto/auth_result_dto.dart';


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
  final _formKey = GlobalKey<FormState>(); // Added for form validation

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
    // Ensure portrait orientation is set as soon as possible for this screen
    _setPortraitOrientation();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _register() async {
    // Validate form fields first
    if (!_formKey.currentState!.validate()) {
      FirebaseAnalytics.instance.logEvent(
        name: 'register_attempt_failed',
        parameters: {
          'reason': 'form_validation_failed',
        },
      );
      PersistentSnackbar.show(
        context: context,
        message: 'Please, fill all fields correctly.',
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        icon: Icons.error_outline,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    // Use AuthResult from AuthController
    final AuthResult result = await _authController.registerUser(username, email, password);

    if (mounted) {
      if (result.success) {
        // Backend now returns a token directly after successful registration
        // You might want to navigate to MainScreen directly, or inform user to check email
        // and navigate to LoginScreen, depending on your desired flow.
        // For now, based on your previous code, navigate to LoginScreen and show message.
        // If the backend automatically logs in and gives token, you can navigate to MainScreen.

        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'Account created and validation code sent!', // Use userMessage
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
          duration: const Duration(seconds: 4),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        FirebaseAnalytics.instance.logEvent(
          name: 'register_attempt_success',
          parameters: {
            'email_hash': email.hashCode, // Log hash for privacy
          },
        );
      } else {
        // Use the userMessage from AuthResult for display
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'Unknown error creating account.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 4),
        );
        FirebaseAnalytics.instance.logEvent(
          name: 'register_attempt_failed',
          parameters: {
            'reason': result.errorMessage ?? 'unknown_backend_error',
            'user_message': result.userMessage ?? 'N/A',
          },
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // --- Input Field Helper Widget ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      height: 60, // Increased height for better tap target
      width: MediaQuery.of(context).size.width * 0.8,
      child: TextFormField( // Changed to TextFormField for validation
        controller: controller,
        style: const TextStyle(color: Colors.white),
        obscureText: obscureText,
        validator: validator, // Add validator
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF57C00).withOpacity(0.7),
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFFFCC80)),
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: const Color(0xFFFFCC80)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          errorBorder: OutlineInputBorder( // Custom error border
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder( // Custom focused error border
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15), // Adjusted padding
        ),
      ),
    );
  }

  Widget _buildCustomButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF9800), // Orange primary color
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
        minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 50), // Ensure button has consistent width
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
  Widget build(BuildContext
  context) {
    // Orientation is set in initState, no need to set it again in build
    _setPortraitOrientation();

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
              child: Form( // Wrap with Form for validation
                key: _formKey,
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
                    const SizedBox(height: 30),

                    // Campo de Username
                    _buildTextField(
                      controller: _usernameController,
                      hintText: "Username",
                      labelText: "Username",
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please, insert an username.';
                        }
                        if (value.length < 3) {
                          return 'Username has to be at least 3 characters long.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Campo de Email
                    _buildTextField(
                      controller: _emailController,
                      hintText: "Email",
                      labelText: "Email address",
                      icon: Icons.email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please, insert your email.';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Email format invalid.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Campo de Senha
                    _buildTextField(
                      controller: _passwordController,
                      hintText: "Password",
                      labelText: "Password",
                      icon: Icons.lock,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please, insert your password.';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters long.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    _buildCustomButton(
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
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        "I already have an accout",
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
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:OrangeScoutFE/view/mainScreen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  final TextEditingController _codeController = TextEditingController();
  String? baseUrl = dotenv.env['API_BASE_URL'];

  final Duration _cooldownDuration = const Duration(minutes: 1);
  DateTime? _lastSentTime;

  @override
  void initState() {
    super.initState();
    _checkCooldownStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  bool get _isCooldownActive {
    if (_lastSentTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastSentTime!) < _cooldownDuration;
  }

  void _checkCooldownStatus() {
    setState(() {
    });
    if (_isCooldownActive) {
      final timeRemaining = _cooldownDuration - DateTime.now().difference(_lastSentTime!);
      Future.delayed(timeRemaining, () {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }


  Future<void> validateCode() async {
    setState(() {
      _isLoading = true;
    });

    String? token = await loadToken();

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Token not found.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/validate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'code': _codeController.text}),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code validated successfully!')),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
                (Route<dynamic> route) => false,
          );
        } else {
          String errorMessage = 'Failed to validate code! Status: ${response.statusCode}';
          if (response.body.isNotEmpty) {
            print('Server response: ${response.body}');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> sendVerificationCode() async {
    if (_isCooldownActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait before resending the code.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? token = await loadToken();

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Token not found.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/sendValidationCode'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code sent successfully!')),
          );
          _lastSentTime = DateTime.now();
          _checkCooldownStatus();
        } else {
          String errorMessage = 'Failed sending code: ${response.statusCode}';
          if (response.body.isNotEmpty) {
            print('Server response: ${response.body}');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return Scaffold(
      body: Container(
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/OrangeScoutLogo.png'),
              const SizedBox(height: 40),
              SizedBox(
                height: 40,
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: _codeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF57C00),
                    hintText: "Validation code",
                    hintStyle: const TextStyle(color: Color(0xFFFFCC80)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : validateCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: _isLoading && _codeController.text.isEmpty
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Validate',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: (_isLoading || _isCooldownActive) ? null : sendVerificationCode,
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: Colors.blue,
                  ),
                )
                    : const Text(
                  'Send verification code',
                  style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Sending...', style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

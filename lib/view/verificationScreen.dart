import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Import Crashlytics

// Import your DTOs
import 'package:OrangeScoutFE/dto/validation_request_dto.dart';
import 'package:OrangeScoutFE/dto/auth_result_dto.dart'; // To get userMessage from AuthController

// Import your controllers
import 'package:OrangeScoutFE/controller/auth_controller.dart';

// Import your utility
import 'package:OrangeScoutFE/util/persistent_snackbar.dart';

// Import your views
import 'package:OrangeScoutFE/view/mainScreen.dart'; // To navigate back to MainScreen

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  final TextEditingController _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Added for form validation

  final AuthController _authController = AuthController();

  final Duration _cooldownDuration = const Duration(minutes: 1); // Cooldown for resending code
  DateTime? _lastSentTime; // Timestamp of the last successful send
  Timer? _cooldownTimer; // Timer for countdown display (optional, but good UX)
  int _remainingCooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _setPortraitOrientation(); // Set orientation early
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'VerificationScreen',
        screenClass: 'VerificationScreenState',
      );
      _checkAndSetCooldownStatus(); // Check cooldown on init
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel(); // Cancel timer to prevent memory leaks
    super.dispose();
  }

  // Ensures portrait orientation
  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Check if cooldown is active and set up timer
  bool get _isCooldownActive {
    if (_lastSentTime == null) {
      return false;
    }
    final diff = DateTime.now().difference(_lastSentTime!);
    return diff < _cooldownDuration;
  }

  void _checkAndSetCooldownStatus() {
    if (_isCooldownActive) {
      final timeRemaining = _cooldownDuration - DateTime.now().difference(_lastSentTime!);
      _remainingCooldownSeconds = timeRemaining.inSeconds;
      _startCooldownTimer();
    } else {
      _remainingCooldownSeconds = 0;
      _cooldownTimer?.cancel();
    }
    setState(() {}); // Update UI
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel(); // Cancel any existing timer
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingCooldownSeconds--;
        if (_remainingCooldownSeconds <= 0) {
          timer.cancel();
          _lastSentTime = null; // Reset last sent time if cooldown finished
          _remainingCooldownSeconds = 0;
        }
      });
    });
  }

  /// Handles sending the validation code to the user's email.
  Future<void> _sendVerificationCode() async {
    FirebaseAnalytics.instance.logEvent(name: 'send_validation_code_button_tapped');
    if (_isCooldownActive) {
      if (mounted) {
        PersistentSnackbar.show(
          context: context,
          message: 'Por favor, aguarde antes de reenviar o código.',
          backgroundColor: Colors.orange.shade700,
          textColor: Colors.white,
          icon: Icons.timer,
          duration: const Duration(seconds: 3),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final AuthResult result = await _authController.sendValidationCode();

    if (mounted) {
      if (result.success) {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'Código enviado com sucesso!',
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
          duration: const Duration(seconds: 3),
        );
        _lastSentTime = DateTime.now(); // Set last sent time on success
        _checkAndSetCooldownStatus(); // Start cooldown timer
        FirebaseAnalytics.instance.logEvent(name: 'validation_code_sent_success');
      } else {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'Falha ao enviar código. Tente novamente.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 4),
        );
        FirebaseAnalytics.instance.logEvent(name: 'validation_code_sent_failed', parameters: {'reason': result.errorMessage});
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Handles validating the code entered by the user.
  Future<void> _validateCode() async {
    FirebaseAnalytics.instance.logEvent(name: 'validate_code_button_tapped');

    if (!_formKey.currentState!.validate()) {
      FirebaseAnalytics.instance.logEvent(name: 'validate_code_failed', parameters: {'reason': 'form_validation_failed'});
      PersistentSnackbar.show(
        context: context,
        message: 'Por favor, insira o código de 6 dígitos.',
        backgroundColor: Colors.red.shade700,
        textColor: Colors.white,
        icon: Icons.error_outline,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final ValidationRequest validationRequest = ValidationRequest(code: _codeController.text);
    final AuthResult result = await _authController.validateUserAccount(validationRequest.code); // Pass code string directly

    if (mounted) {
      if (result.success) {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'E-mail validado com sucesso!',
          backgroundColor: Colors.green.shade700,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
          duration: const Duration(seconds: 3),
        );
        FirebaseAnalytics.instance.logEvent(name: 'account_validated_success');
        // Clear navigation stack and go to MainScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
        );
      } else {
        PersistentSnackbar.show(
          context: context,
          message: result.userMessage ?? 'Código inválido ou expirado. Tente novamente.',
          backgroundColor: Colors.red.shade700,
          textColor: Colors.white,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 4),
        );
        FirebaseAnalytics.instance.logEvent(name: 'account_validated_failed', parameters: {'reason': result.errorMessage});
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // --- Input Field Helper Widget (Copied from Login/Register for consistency) ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text, // Added keyboardType
  }) {
    return SizedBox(
      height: 60,
      width: MediaQuery.of(context).size.width * 0.8,
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        obscureText: obscureText,
        validator: validator,
        keyboardType: keyboardType, // Use keyboardType
        inputFormatters: keyboardType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null, // Only digits for number input
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Orientation is set in initState, no need to set it again in build
    _setPortraitOrientation();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Validação de E-mail", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3A2E2E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // This screen typically replaces login/register, so popping might go to MainScreen
            // If user comes from MainScreen (e.g., from VerificationBanner), they can pop back.
            Navigator.pop(context);
          },
        ),
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form( // Wrap with Form for validation
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/OrangeScoutLogo.png',
                    height: 150, // Adjusted size
                    width: 150, // Adjusted size
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Um código de validação foi enviado para o seu e-mail. Por favor, insira-o abaixo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField( // Use helper for consistency
                    controller: _codeController,
                    hintText: "Código de Validação",
                    labelText: "Código de 6 dígitos",
                    icon: Icons.vpn_key,
                    keyboardType: TextInputType.number, // Numeric keyboard
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'O código não pode estar em branco.';
                      }
                      if (value.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'O código deve ter 6 dígitos numéricos.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _validateCode, // Call private validate method
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Validar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: (_isLoading || _isCooldownActive) ? null : _sendVerificationCode, // Call private send method
                    child: _isLoading && _lastSentTime == null // Only show progress for sending if it's the first send or during sending
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.blue,
                      ),
                    )
                        : Text(
                      _isCooldownActive
                          ? 'Reenviar código em ($_remainingCooldownSeconds s)'
                          : 'Reenviar código',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: (_isLoading || _isCooldownActive) ? Colors.grey : Colors.blue,
                      ),
                    ),
                  ),
                  if (_isLoading && _lastSentTime == null) // Show "Sending..." only for the initial send
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text('Enviando...', style: TextStyle(color: Colors.grey)),
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
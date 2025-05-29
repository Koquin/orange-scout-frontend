import 'package:OrangeScoutFE/view/createTeamScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:OrangeScoutFE/view/mainScreen.dart';
import 'package:OrangeScoutFE/view/historyScreen.dart';
import 'package:OrangeScoutFE/view/registerScreen.dart';
import 'package:OrangeScoutFE/view/loginScreen.dart';
import 'package:OrangeScoutFE/view/verificationScreen.dart';
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:async';
import 'package:OrangeScoutFE/controller/userController.dart';
import 'package:OrangeScoutFE/controller/authController.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Error loading .env file: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  runZonedGuarded(() async {
    final AuthController authController = AuthController();
    String? token = await loadToken();
    bool expiredToken = token == null || await authController.isTokenExpired(token);
    runApp(MyApp(expiredToken: expiredToken));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    if (kDebugMode) {
      print('Unhandled error caught by runZonedGuarded: $error');
      print(stack);
    }
  });
}

class MyApp extends StatelessWidget {
  final bool expiredToken;

  const MyApp({super.key, required this.expiredToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orange Scout',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: expiredToken ? LoginScreen() : MainScreen(),
      routes: {
        '/main': (context) => MainScreen(),
        '/history': (context) => HistoryScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/validationScreen': (context) => VerificationScreen(),
        '/createTeam': (context) => CreateTeamScreen(teamId: null),
      },
    );
  }
}

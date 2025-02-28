import 'package:shared_preferences/shared_preferences.dart';


Future<String?> loadToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}
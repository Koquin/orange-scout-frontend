import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:OrangeScoutFE/util/token_utils.dart';

Future<bool> checkUserValidation() async {
  String? token = await loadToken();

  try {
    final response = await http.get(
      Uri.parse('http://192.168.18.31:8080/auth/isValidated'),
      headers: {
        'Authorization' : 'Bearer $token',
        'Content-Type': 'application/json',
      }
    );

    if (response.statusCode == 200) {
      if (response.body.trim().toLowerCase() == 'true'){
        print("Requisition for User Validation was successful, Response is TRUE");
        return true;
      }
      else {
        print("Requisition User Validation was successful, Response is FALSE");
        return false;
      }
    } else {
      print("Requisition code was other than 200");
      return false;
    }
  } catch (e) {
    print("Requisition error: $e");
    return false;
  }
}

Future<bool> checkUserTeams() async {
  String? token = await loadToken();

  try {
    final response = await http.get(
      Uri.parse('http://192.168.18.31:8080/match/validate-start'),
      headers : {
        'Authorization' : 'Bearer $token',
        'Content-Type': 'application/json',
        }
    );

    if (response.statusCode == 200) {
      if (response.body.trim().toLowerCase() == 'true'){
        print("Requisition for User Teams was successful, response is TRUE");
        return true;
      }
      else {
        print("Requisition for User Teams was successful, response is FALSE");
        return false;
      }
    } else {
      print("Requisition code was other than 200");
      return false;
    }
  } catch (e) {
    print("Requisition error: $e");
    return false;
  }
}

Future<bool> validateToken(String? token) async {
  if (token == null || token.isEmpty) return false;

  try {
    final response = await http.post(
      Uri.parse('http://192.168.18.31:8080/auth/isTokenValid'),
        headers : {
          'Authorization' : 'Bearer $token',
          'Content-Type': 'application/json',
        },
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      return response.body.trim().toLowerCase() == 'true';
    } else {
      return false;
    }
  } catch (e) {
    print("Requisition error: $e");
    return false;
  }
}

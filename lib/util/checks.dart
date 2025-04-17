import 'package:http/http.dart' as http;
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
      print("Requisition code was other than 200 for User Validation");
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
      print("Requisition code was other than for User Teams");
      return false;
    }
  } catch (e) {
    print("Requisition error: $e");
    return false;
  }
}

Future<bool> isTokenExpired(String? token) async {
  if (token == null || token.isEmpty) return false;

  try {
    final response = await http.post(
      Uri.parse('http://192.168.18.31:8080/auth/isTokenValid'),
        headers : {
          'Content-Type': 'application/json',
        },
      body: jsonEncode({'token': token}),
    );
    print(response.body);
    if (response.statusCode == 200) {
      print("Response for token is valid is 200");
      if (response.body.trim().toLowerCase() == 'false'){
        return false;
      }
      else {
        return true;
      }
    } else if (response.statusCode == 403) {
      print("Response for token is valid is 403");
      return true;
    } else {
      print("Response for token is valid is other");
      return true;
    }
  } catch (e) {
    print("Requisition error: $e");
    return false;
  }
}

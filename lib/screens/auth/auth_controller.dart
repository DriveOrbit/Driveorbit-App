import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> login(String userId, String password) async {
  final response = await http.post(
    Uri.parse(
        'http://10.0.2.2:8080/auth/login'), // Use '10.0.2.2' if running on an Android emulator
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'userID': userId, // Ensure 'userID' is used instead of 'userId'
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    final responseBody = jsonDecode(response.body);
    return responseBody['token'];
  } else if (response.statusCode == 400) {
    // Handle non-JSON response
    return response.body;
  } else {
    throw Exception('Failed to login');
  }
}

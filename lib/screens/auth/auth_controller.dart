import 'dart:convert';
import 'package:http/http.dart' as http;

// Mock user credentials
const Map<String, String> mockUsers = {
  'admin': 'admin123',
  'driver1': 'password123',
  'test': 'test123',
};

bool useMockAuth = true; // Toggle between mock and real authentication

Future<String?> login(String userId, String password) async {
  if (useMockAuth) {
    // Mock authentication logic
    if (mockUsers.containsKey(userId) && mockUsers[userId] == password) {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mockToken'; // Mock JWT token
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      return 'Invalid username or password';
    }
  }

  // Real API authentication logic
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'userID': userId,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['token'];
    } else if (response.statusCode == 400) {
      return response.body;
    } else {
      throw Exception('Failed to login');
    }
  } catch (e) {
    if (e is Exception) {
      return 'Network error: Please check your connection';
    }
    return 'An unexpected error occurred';
  }
}

Future<Map<String, dynamic>> sendUserId(String userId) async {
  if (useMockAuth) {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mockUsers.containsKey(userId)) {
      return {
        'statusCode': 200,
        'body': 'OTP sent successfully to your email',
      };
    } else {
      return {
        'statusCode': 400,
        'body': 'User not found',
      };
    }
  }

  // Real API logic
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/auth/forgot-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'userID': userId,
      }),
    );

    return {
      'statusCode': response.statusCode,
      'body': response.body,
    };
  } catch (e) {
    return {
      'statusCode': 500,
      'body': 'Network error: Please check your connection',
    };
  }
}
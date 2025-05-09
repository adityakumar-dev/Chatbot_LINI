import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final http.Client _client;
  final SharedPreferences _prefs;
  static const String _baseUrl = 'https://enabled-flowing-bedbug.ngrok-free.app/api'; // TODO: Replace with actual API URL
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  ApiService(this._client, this._prefs);

  String? get _token => _prefs.getString(_tokenKey);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          await _prefs.setString(_tokenKey, data['access_token']);
          await _prefs.setInt(_userIdKey, data['user_id']);
          return {
            'success': true,
            'message': 'Login successful!',
            'data': data,
          };
        }
        return {
          'success': false,
          'message': 'Login failed. Please try again.',
        };
      }
      return {
        'success': false,
        'message': 'Login failed. Please check your credentials.',
      };
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          await _prefs.setString(_tokenKey, data['access_token']);
          await _prefs.setInt(_userIdKey, data['user_id']);
          return {
            'success': true,
            'message': 'Registration successful!',
            'data': data,
          };
        }
        return {
          'success': false,
          'message': 'Registration failed. Please try again.',
        };
      }
      return {
        'success': false,
        'message': 'Registration failed. Please try again.',
      };
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _client.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _headers,
      );
    } finally {
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_userIdKey);
    }
  }

  Future<bool> checkAuth() async {
    if (_token == null) return false;

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/auth/check'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> sendMessage(String message, {bool isSearch = false, int? conversationId}) async {
    try {
      final userId = _prefs.getInt(_userIdKey);
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/chat'),
      );

      request.headers.addAll(_headers);
      request.fields.addAll({
        'user_id': userId.toString(),
        'prompt': message,
        'is_search': isSearch.toString(),
      });

      if (conversationId != null) {
        request.fields['conversation_id'] = conversationId.toString();
      }

      final response = await request.send();
      final responseBytes = await response.stream.toBytes();
      final responseBody = utf8.decode(responseBytes);

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      }
      throw Exception('Failed to send message');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<Map<String, dynamic>> sendImage(String imagePath, {int? conversationId}) async {
    try {
      final userId = _prefs.getInt(_userIdKey);
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/chat'),
      );

      request.headers.addAll(_headers);
      request.fields.addAll({
        'user_id': userId.toString(),
        'prompt': 'Analyze this image',
        'is_search': 'false',
      });

      if (conversationId != null) {
        request.fields['conversation_id'] = conversationId.toString();
      }

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final response = await request.send();
      final responseBytes = await response.stream.toBytes();
      final responseBody = utf8.decode(responseBytes);

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      }
      throw Exception('Failed to send image');
    } catch (e) {
      throw Exception('Failed to send image: $e');
    }
  }

  Future<Map<String, dynamic>> getChatHistory() async {
    try {
      final userId = _prefs.getInt(_userIdKey);
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final response = await _client.get(
        Uri.parse('$_baseUrl/chat/history/user/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return jsonDecode(decodedBody);
      }
      throw Exception('Failed to get chat history');
    } catch (e) {
      throw Exception('Failed to get chat history: $e');
    }
  }
} 
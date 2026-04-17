import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:company_admin/src/core/constants/api_constants.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Helper to prepend base URL if not already present
  String _normalizeUrl(String url) {
    if (url.startsWith('http')) return url;
    // Ensure no double slashes if ApiConstants.baseUrl ends with /
    final baseUrl = ApiConstants.baseUrl.endsWith('/')
        ? ApiConstants.baseUrl
        : '${ApiConstants.baseUrl}/';
    return '$baseUrl$url';
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'x-app-id': 'Admin App',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String url) async {
    try {
      final response = await _client.get(
        Uri.parse(_normalizeUrl(url)),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) rethrow;
      throw Exception('Connection Error: $e');
    }
  }

  Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await _client.post(
        Uri.parse(_normalizeUrl(url)),
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) rethrow;
      throw Exception('Connection Error: $e');
    }
  }

  Future<dynamic> put(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await _client.put(
        Uri.parse(_normalizeUrl(url)),
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) rethrow;
      throw Exception('Connection Error: $e');
    }
  }

  Future<dynamic> delete(String url) async {
    try {
      final response = await _client.delete(
        Uri.parse(_normalizeUrl(url)),
        headers: await _getHeaders(),
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) rethrow;
      throw Exception('Connection Error: $e');
    }
  }

  Future<dynamic> patch(String url, {Map<String, dynamic>? body}) async {
    try {
      final response = await _client.patch(
        Uri.parse(_normalizeUrl(url)),
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) rethrow;
      throw Exception('Connection Error: $e');
    }
  }

  Future<dynamic> postMultipart(
    String url, {
    Map<String, String>? fields,
    Map<String, String>? files, // key: path
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_normalizeUrl(url)),
      );
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (files != null) {
        for (final entry in files.entries) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, entry.value),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) rethrow;
      throw Exception('Connection Error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return response.body;
      }
    } else {
      String message = 'Status Code: ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        message =
            body['message'] ?? body['error'] ?? 'Error: ${response.statusCode}';
      } catch (_) {
        message = 'Server Error: ${response.statusCode}';
      }
      throw Exception(message);
    }
  }
}

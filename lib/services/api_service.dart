import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });
}

/// Main API Service
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  String _baseUrl = ApiConstants.baseUrl;

  /// Set the auth token for authenticated requests
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Set the base URL (useful for switching between dev/prod)
  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  /// Get the appropriate base URL based on platform
  String get baseUrl {
    if (kIsWeb) {
      return ApiConstants.baseUrl;
    }
    if (Platform.isAndroid) {
      // Use 10.0.2.2 for Android emulator
      return _baseUrl.contains('localhost')
          ? _baseUrl.replaceAll('localhost', '10.0.2.2')
          : _baseUrl;
    }
    return _baseUrl;
  }

  /// Build headers for requests
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        statusCode: 0,
      );
    }
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        statusCode: 0,
      );
    }
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        statusCode: 0,
      );
    }
  }

  /// PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.patch(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        statusCode: 0,
      );
    }
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic json)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(uri, headers: _headers);
      return _handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        statusCode: 0,
      );
    }
  }

  /// Handle API response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? fromJson,
  ) {
    final statusCode = response.statusCode;
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (statusCode >= 200 && statusCode < 300) {
      // Success
      T? data;

      // Check if response has pagination (keep full structure for paginated responses)
      final hasPagination = body is Map && (body as Map).containsKey('pagination');

      // Extract 'data' field only if no pagination (single item responses)
      final responseData = (body is Map && body.containsKey('data') && !hasPagination)
          ? body['data']
          : body;

      if (fromJson != null && responseData != null) {
        data = fromJson(responseData);
      } else if (responseData != null) {
        data = responseData as T?;
      }

      return ApiResponse(
        success: true,
        data: data,
        statusCode: statusCode,
      );
    } else {
      // Error
      String errorMessage = 'Request failed';
      if (body != null && body is Map) {
        errorMessage = body['error'] ?? body['message'] ?? errorMessage;
      }

      return ApiResponse(
        success: false,
        error: errorMessage,
        statusCode: statusCode,
      );
    }
  }
}

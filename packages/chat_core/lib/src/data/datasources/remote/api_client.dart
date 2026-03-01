import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../core/exceptions.dart';
import 'token_storage.dart';

/// Parsed API response: data payload and optional pagination meta.
typedef ApiResponse = ({Map<String, dynamic>? data, Map<String, dynamic>? meta});

/// HTTP client for the Chat SDK REST API.
///
/// Responsibilities:
/// - Adds `Authorization: Bearer <token>` to every request.
/// - On 401, attempts a single token refresh then retries the original request.
/// - Parses the `{"data": ..., "meta": ...}` envelope.
/// - Converts HTTP / network errors into typed [Exception]s.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    this.onAuthFailure,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;

  /// Called when a 401 cannot be recovered by token refresh (session expired).
  final void Function()? onAuthFailure;

  final http.Client _http;
  bool _isRefreshing = false;

  // ── Public request methods ───────────────────────────────────────────────

  Future<ApiResponse> get(
    String path, {
    Map<String, String>? queryParams,
  }) =>
      _request('GET', path, queryParams: queryParams);

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) =>
      _request('POST', path, body: body, extraHeaders: headers);

  Future<ApiResponse> patch(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _request('PATCH', path, body: body);

  Future<ApiResponse> delete(String path) => _request('DELETE', path);

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<ApiResponse> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
    bool allowRetry = true,
  }) async {
    try {
      final response = await _execute(
        method,
        path,
        body: body,
        queryParams: queryParams,
        extraHeaders: extraHeaders,
      );

      if (response.statusCode == 401 && allowRetry && !_isRefreshing) {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          return _request(
            method,
            path,
            body: body,
            queryParams: queryParams,
            extraHeaders: extraHeaders,
            allowRetry: false,
          );
        } else {
          onAuthFailure?.call();
          throw const AuthException(
            message: 'Session expired. Please log in again.',
            errorCode: 'UNAUTHORIZED',
          );
        }
      }

      return _parseResponse(response);
    } on TimeoutException {
      throw const NetworkException(message: 'Request timed out.');
    } on http.ClientException catch (e) {
      throw NetworkException(message: e.message);
    }
  }

  Future<http.Response> _execute(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final token = await tokenStorage.getAccessToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?extraHeaders,
    };

    final encodedBody = body != null ? jsonEncode(body) : null;

    switch (method) {
      case 'GET':
        return _http
            .get(uri, headers: headers)
            .timeout(ApiConstants.receiveTimeout);
      case 'POST':
        return _http
            .post(uri, headers: headers, body: encodedBody)
            .timeout(ApiConstants.receiveTimeout);
      case 'PATCH':
        return _http
            .patch(uri, headers: headers, body: encodedBody)
            .timeout(ApiConstants.receiveTimeout);
      case 'DELETE':
        return _http
            .delete(uri, headers: headers)
            .timeout(ApiConstants.receiveTimeout);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Attempts to refresh the access token.
  /// Returns true if successful and new tokens are saved.
  Future<bool> _tryRefresh() async {
    _isRefreshing = true;
    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await _http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>;
        await tokenStorage.saveTokens(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token'] as String,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  ApiResponse _parseResponse(http.Response response) {
    // No-content responses
    if (response.statusCode == 204 || response.body.isEmpty) {
      return (data: null, meta: null);
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ServerException(
        message: 'Invalid response format from server.',
        statusCode: response.statusCode,
        errorCode: 'PARSE_ERROR',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (
        data: json['data'] as Map<String, dynamic>?,
        meta: json['meta'] as Map<String, dynamic>?,
      );
    }

    // Structured error response
    final error = (json['error'] as Map<String, dynamic>?) ?? {};
    final errorCode = (error['code'] as String?) ?? 'INTERNAL_ERROR';
    final message =
        (error['message'] as String?) ?? 'An unexpected error occurred.';

    if (response.statusCode == 401) {
      throw AuthException(message: message, errorCode: errorCode);
    }
    throw ServerException(
      message: message,
      statusCode: response.statusCode,
      errorCode: errorCode,
    );
  }

  void dispose() => _http.close();
}

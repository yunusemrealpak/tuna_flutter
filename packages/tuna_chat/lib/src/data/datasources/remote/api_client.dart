import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../core/exceptions.dart';

/// Parsed API response: data payload and optional pagination meta.
typedef ApiResponse = ({Map<String, dynamic>? data, Map<String, dynamic>? meta});

/// HTTP client for the TunaChat SDK REST API.
///
/// Responsibilities:
/// - Adds `X-API-Key: <apiKey>` to every request (app identification).
/// - Adds `Authorization: Bearer <token>` when a user is connected.
/// - On 401, calls [tokenProvider] (if set) for a fresh token, then retries.
/// - Parses the `{"data": ..., "meta": ...}` envelope.
/// - Converts HTTP / network errors into typed [Exception]s.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.apiKey,
    String? token,
    this.tokenProvider,
    this.onAuthFailure,
    http.Client? httpClient,
  })  : _token = token,
        _http = httpClient ?? http.Client();

  final String baseUrl;

  /// Public API key (X-API-Key header). Identifies the app to the backend.
  final String apiKey;

  /// Async callback that returns a fresh token when the current one expires.
  /// If null and a 401 is received, [onAuthFailure] is called.
  final Future<String?> Function()? tokenProvider;

  /// Called when authentication cannot be recovered.
  final void Function()? onAuthFailure;

  final http.Client _http;
  String? _token;
  bool _isRefreshing = false;

  // ── Token management ─────────────────────────────────────────────────────

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;
  String? get token => _token;

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

  Future<ApiResponse> delete(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _request('DELETE', path, body: body);

  /// Uploads a file via `multipart/form-data POST`.
  ///
  /// The file is sent as the `file` form field. Auth headers are applied
  /// identically to regular requests. On 401 a single token-refresh retry
  /// is attempted via [tokenProvider].
  Future<ApiResponse> postMultipart(
    String path, {
    required List<int> fileBytes,
    required String fileName,
    bool allowRetry = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          'X-API-Key': apiKey,
          if (_token != null) 'Authorization': 'Bearer $_token',
        })
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: fileName,
          ),
        );

      final streamed =
          await request.send().timeout(ApiConstants.receiveTimeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 401 && allowRetry && !_isRefreshing) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return postMultipart(path,
              fileBytes: fileBytes, fileName: fileName, allowRetry: false);
        } else {
          onAuthFailure?.call();
          throw const AuthException(
            message: 'Session expired. Please reconnect.',
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
        final refreshed = await _tryRefreshToken();
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
            message: 'Session expired. Please reconnect.',
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

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-API-Key': apiKey,
      if (_token != null) 'Authorization': 'Bearer $_token',
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
            .delete(uri, headers: headers, body: encodedBody)
            .timeout(ApiConstants.receiveTimeout);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Attempts to get a fresh token via [tokenProvider].
  /// Returns true if a new token was obtained and set.
  Future<bool> _tryRefreshToken() async {
    if (tokenProvider == null) return false;
    _isRefreshing = true;
    try {
      final newToken = await tokenProvider!();
      if (newToken != null) {
        _token = newToken;
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

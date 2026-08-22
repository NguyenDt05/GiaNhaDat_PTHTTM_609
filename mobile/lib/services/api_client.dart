import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/location_option.dart';
import '../models/prediction.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => message;
}

class HousePriceApiClient {
  HousePriceApiClient({
    required String baseUrl,
    this.bearerToken,
    http.Client? client,
  })  : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  factory HousePriceApiClient.fromEnvironment() {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    );
    const token = String.fromEnvironment('API_BEARER_TOKEN');
    return HousePriceApiClient(
      baseUrl: baseUrl,
      bearerToken: token.isEmpty ? null : token,
    );
  }

  final String baseUrl;
  final String? bearerToken;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
        if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
      };

  Future<LocationOptions> fetchLocationOptions() async {
    final response = await _sendWithRetry(
      () =>
          _client.get(Uri.parse('$baseUrl/api/v1/options'), headers: _headers),
    );
    return LocationOptions.fromJson(_decode(response));
  }

  Future<PredictionResult> predict(PredictionInput input) async {
    final response = await _sendWithRetry(
      () => _client.post(
        Uri.parse('$baseUrl/api/v1/predictions'),
        headers: _headers,
        body: jsonEncode(input.toJson()),
      ),
    );
    return PredictionResult.fromApiJson(_decode(response));
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() operation,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await operation().timeout(const Duration(seconds: 15));
        if (response.statusCode >= 500 && attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        return response;
      } on SocketException catch (error) {
        lastError = error;
      } on TimeoutException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }
      if (attempt == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    throw ApiException(
      lastError is TimeoutException
          ? 'Máy chủ phản hồi quá chậm. Vui lòng thử lại.'
          : 'Không thể kết nối máy chủ. Vui lòng kiểm tra Internet.',
      code: 'NETWORK_ERROR',
    );
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.bodyBytes.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      throw ApiException(
        error['message'] as String? ?? 'Yêu cầu không thành công.',
        code: error['code'] as String?,
        statusCode: response.statusCode,
      );
    }
    throw ApiException(
      'Máy chủ trả về lỗi ${response.statusCode}.',
      statusCode: response.statusCode,
    );
  }

  void close() => _client.close();
}

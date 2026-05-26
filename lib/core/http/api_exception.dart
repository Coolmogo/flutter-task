import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDioException(DioException exception) {
    final response = exception.response;
    final statusCode = response?.statusCode;
    final responseData = response?.data;

    String message;
    if (responseData is Map<String, dynamic>) {
      message =
          (responseData['message'] ??
                  responseData['error'] ??
                  responseData['detail'])
              ?.toString() ??
          exception.message ??
          'Unexpected API error';
    } else if (responseData is String && responseData.trim().isNotEmpty) {
      message = responseData;
    } else {
      message = exception.message ?? 'Unexpected API error';
    }

    return ApiException(message, statusCode: statusCode);
  }

  factory ApiException.invalidResponse([String? message]) {
    return ApiException(message ?? 'The server returned an invalid response.');
  }

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }

    return 'ApiException($statusCode): $message';
  }
}

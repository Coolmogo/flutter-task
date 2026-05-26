import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/core/http/api_exception.dart';

class AppInterceptors extends Interceptor {
  final Ref ref;
  final bool enableLogging;

  AppInterceptors({
    required this.ref,
    this.enableLogging = false,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Backend meeting extension point:
    // attach auth and tenant headers here once the contract is confirmed.
    if (enableLogging) {
      log(
        '[HTTP] ${options.method} ${options.baseUrl}${options.path}',
        name: 'AppInterceptors',
      );
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (enableLogging) {
      log(
        '[HTTP] ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.baseUrl}${response.requestOptions.path}',
        name: 'AppInterceptors',
      );
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enableLogging) {
      log(
        '[HTTP] ERROR ${err.requestOptions.method} '
        '${err.requestOptions.baseUrl}${err.requestOptions.path}: '
        '${err.message}',
        name: 'AppInterceptors',
      );
    }

    handler.reject(err.copyWith(error: ApiException.fromDioException(err)));
  }
}

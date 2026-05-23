import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  static const _enc = JsonEncoder.withIndent('  ');
  static const _border =
      '╔══════════════════════════════════════════════════';
  static const _footer =
      '╚══════════════════════════════════════════════════';

  void _p(String line) => debugPrint(line);

  void _printBody(String label, dynamic data) {
    if (data == null) {
      _p('║  $label : (empty)');
      return;
    }
    _p('║  $label :');
    try {
      final pretty = _enc.convert(data);
      for (final line in pretty.split('\n')) {
        _p('║    $line');
      }
    } catch (_) {
      _p('║    $data');
    }
  }

  void _printHeaders(Map<String, dynamic> headers) {
    if (headers.isEmpty) return;
    _p('║  Headers :');
    for (final e in headers.entries) {
      final val = e.value.toString();
      // Truncate long auth tokens for readability.
      final display = val.length > 60
          ? '${val.substring(0, 40)}…${val.substring(val.length - 10)}'
          : val;
      _p('║    ${e.key}: $display');
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _p(_border);
      _p('║ ➡  REQUEST');
      _p('║  Method  : ${options.method}');
      _p('║  URL     : ${options.uri}');
      _printHeaders(options.headers);
      _printBody('Body', options.data);
      _p(_footer);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _p(_border);
      _p('║ ✅ RESPONSE');
      _p('║  Status  : ${response.statusCode}');
      _p('║  URL     : ${response.requestOptions.uri}');
      _printBody('Body', response.data);
      _p(_footer);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _p(_border);
      _p('║ ❌ ERROR');
      _p('║  Type    : ${err.type}');
      _p('║  URL     : ${err.requestOptions.uri}');
      _p('║  Status  : ${err.response?.statusCode ?? '-'}');
      _printBody('Body', err.response?.data);
      _p(_footer);
    }
    handler.next(err);
  }
}

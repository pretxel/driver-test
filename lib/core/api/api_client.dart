// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _baseUrl =
    'https://vfmtrozkajbwaxdgdmys.supabase.co/functions/v1/api';

Dio createApiClient() {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.accessToken}';
      }
      handler.next(options);
    },
  ));

  return dio;
}

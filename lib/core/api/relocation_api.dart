// lib/core/api/relocation_api.dart
import 'package:dio/dio.dart';
import '../models/relocation.dart';

class RelocationApi {
  RelocationApi(this._dio);

  final Dio _dio;

  /// GET /api/v1/relocations?status=PENDING — returns relocations available to book
  Future<List<Relocation>> fetchPendingRelocations() async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/relocations',
      queryParameters: {'status': 'PENDING'},
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Relocation.fromJson)
        .toList();
  }

  /// GET /api/v1/relocations?userId=<id> — returns driver's own jobs
  Future<List<Relocation>> fetchMyRelocations(String userId) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/relocations'
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Relocation.fromJson)
        .toList();
  }

  /// PUT /api/v1/relocations/{id}/confirm — confirms a relocation booking
  Future<Relocation> bookRelocation(String id) async {
    final response = await _dio
        .post<Map<String, dynamic>>('/api/v1/relocations/$id/confirm');
    return Relocation.fromJson(response.data!);
  }
}

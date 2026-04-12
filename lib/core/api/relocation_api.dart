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

  /// GET /api/v1/relocations — returns driver's own jobs (non-pending)
  Future<List<Relocation>> fetchMyRelocations() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/relocations');
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(Relocation.fromJson)
        .toList();
  }

  /// PUT /api/v1/relocations/{id} — books a relocation (PENDING → IN_PROGRESS)
  Future<Relocation> bookRelocation(String id) async {
    final response =
        await _dio.put<Map<String, dynamic>>('/api/v1/relocations/$id');
    return Relocation.fromJson(response.data!);
  }
}

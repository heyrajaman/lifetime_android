import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepository(ref.read(apiClientProvider));
});

class AdminDashboardRepository {
  final ApiClient _apiClient;

  AdminDashboardRepository(this._apiClient);

  Future<List<dynamic>> getApplicants() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAllApplicants);
      // Assuming the backend wraps the array in a 'data' field or returns it directly
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to load applicants.');
    }
  }

  Future<List<dynamic>> getMembers() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getAllMembers);
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to load members.');
    }
  }

  Future<void> toggleMemberStatus(String id) async {
    try {
      await _apiClient.dio.patch(ApiEndpoints.toggleMemberStatus(id));
    } catch (e) {
      throw Exception('Failed to toggle member status.');
    }
  }

  Future<void> updateFee(double newAmount) async {
    try {
      await _apiClient.dio.patch(
        ApiEndpoints.updateFee,
        data: {'amount': newAmount},
      );
    } catch (e) {
      throw Exception('Failed to update fee.');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats({String? startDate, String? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _apiClient.dio.get(
        ApiEndpoints.getDashboardStats,
        queryParameters: queryParams,
      );

      // Backend returns { success: true, message: ..., data: {...} }
      // based on your admin.controller.js, actually admin.service.js returns {success, message, data}
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to load dashboard statistics.');
    }
  }

  Future<List<int>> downloadReport({String? startDate, String? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _apiClient.dio.get<List<int>>(
        ApiEndpoints.exportDashboardReport,
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes), // Ensure we get the raw file bytes
      );

      return response.data ?? [];
    } catch (e) {
      throw Exception('Failed to download report.');
    }
  }

  Future<List<dynamic>> getRegionsAdmin() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getRegionsAdmin);
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to load regions.');
    }
  }

  Future<void> addRegionAdmin(String name) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.addRegionAdmin,
        data: {'name': name},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to add region.');
    }
  }

  Future<void> toggleRegionAdmin(String id) async {
    try {
      await _apiClient.dio.patch(ApiEndpoints.toggleRegionAdmin(id));
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to toggle region.');
    }
  }
}
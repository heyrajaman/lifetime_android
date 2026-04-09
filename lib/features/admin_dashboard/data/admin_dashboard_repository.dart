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
}
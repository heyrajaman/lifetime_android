import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

final editApplicationRepositoryProvider = Provider<EditApplicationRepository>((ref) {
  return EditApplicationRepository(ref.read(apiClientProvider));
});

class EditApplicationRepository {
  final ApiClient _apiClient;

  EditApplicationRepository(this._apiClient);

  Future<Map<String, dynamic>> getApplicantById(String id) async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getApplicantById(id));
      return response.data['data'] ?? response.data;
    } catch (e) {
      throw Exception('Failed to load applicant details.');
    }
  }

  Future<void> updateApplicant(String id, Map<String, dynamic> updateData) async {
    try {
      await _apiClient.dio.put(
        ApiEndpoints.adminEditApplicant(id),
        data: updateData,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update application.');
    }
  }

  Future<void> reviewApplicant(String id, String action) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.reviewApplicant(id),
        data: {'action': action},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to submit review.');
    }
  }

  Future<void> promoteToMember(String applicantId, String registrationNumber) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.promoteApplicant,
        data: {
          'applicantId': applicantId,
          'registrationNumber': registrationNumber,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to promote applicant.');
    }
  }
}
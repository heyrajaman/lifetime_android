import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

final applicationRepositoryProvider = Provider<ApplicationRepository>((ref) {
  return ApplicationRepository(ref.read(apiClientProvider));
});

class ApplicationRepository {
  final ApiClient _apiClient;

  ApplicationRepository(this._apiClient);

  Future<List<dynamic>> getActiveRegions() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.getRegions);
      print('🟢 REGION RAW RESPONSE: ${response.data}');
      if (response.data is List) {
        return response.data;
      } else if (response.data['data'] != null) {
        return response.data['data'];
      } else if (response.data['regions'] != null) { // Common alternative
        return response.data['regions'];
      }

      return response.data;
    } catch (e) {
      if (e is DioException) {
        print('🔴 EXACT URL FAILED: ${e.requestOptions.uri}');
      }
      print('🔴 REGION FETCH ERROR: $e');
      return []; // Return empty if fails, handled gracefully in UI
    }
  }

  Future<List<dynamic>> searchMembers(String term) async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.searchMembers(term));
      return response.data['data'] ?? response.data;
    } catch (e) {
      return [];
    }
  }

  Future<void> submitApplication({
    required Map<String, dynamic> textData,
    required File applicantPhoto,
    required File applicantSignature,
    required File aadharFront,
    required File aadharBack,
  }) async {
    try {
      // 1. Convert text data to string map for FormData
      final Map<String, dynamic> formDataMap = {};
      textData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          formDataMap[key] = value.toString();
        }
      });

      // 2. Add files
      formDataMap['applicant_photo'] = await MultipartFile.fromFile(applicantPhoto.path);
      formDataMap['applicant_signature'] = await MultipartFile.fromFile(applicantSignature.path);
      formDataMap['aadhar_front'] = await MultipartFile.fromFile(aadharFront.path);
      formDataMap['aadhar_back'] = await MultipartFile.fromFile(aadharBack.path);
      formDataMap['membership_type'] = 'LIFETIME';

      final formData = FormData.fromMap(formDataMap);

      await _apiClient.dio.post(
        ApiEndpoints.submitApplication,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      final errors = e.response?.data['errors'];
      if (errors != null && errors is List && errors.isNotEmpty) {
        throw Exception(errors.join('\n'));
      }
      throw Exception(e.response?.data['message'] ?? 'Failed to submit application.');
    } catch (e) {
      throw Exception('An unexpected error occurred.');
    }
  }
}
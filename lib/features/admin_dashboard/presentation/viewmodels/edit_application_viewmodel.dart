import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/edit_application_repository.dart';

final applicantDetailsProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, id) async {
  return ref.read(editApplicationRepositoryProvider).getApplicantById(id);
});

final editAppViewModelProvider = StateNotifierProvider<EditAppViewModel, AsyncValue<void>>((ref) {
  return EditAppViewModel(ref.read(editApplicationRepositoryProvider));
});

class EditAppViewModel extends StateNotifier<AsyncValue<void>> {
  final EditApplicationRepository _repository;

  EditAppViewModel(this._repository) : super(const AsyncData(null));

  Future<bool> updateApplicant(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      await _repository.updateApplicant(id, data);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> reviewApplicant(String id, String action) async {
    state = const AsyncLoading();
    try {
      await _repository.reviewApplicant(id, action);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }

  Future<bool> promoteApplicant(String id, String registrationNumber) async {
    if (registrationNumber.trim().isEmpty) return false;

    state = const AsyncLoading();
    try {
      await _repository.promoteToMember(id, registrationNumber);
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return false;
    }
  }
}
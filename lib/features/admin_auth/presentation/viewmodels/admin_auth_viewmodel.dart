import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_auth_repository.dart';

final adminAuthViewModelProvider =
StateNotifierProvider<AdminAuthViewModel, AsyncValue<void>>((ref) {
  return AdminAuthViewModel(ref.read(adminAuthRepositoryProvider));
});

class AdminAuthViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminAuthRepository _repository;

  AdminAuthViewModel(this._repository)
      : super(const AsyncData(null));

  Future<bool> login(String phoneNumber, String password) async {
    state = const AsyncLoading();

    try {
      await _repository.login(phoneNumber, password);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
  }

  Future<bool> forgotPassword(String email) async {
    state = const AsyncLoading();
    try {
      await _repository.forgotPassword(email);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    state = const AsyncLoading();
    try {
      await _repository.resetPassword(email, otp, newPassword);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    state = const AsyncLoading();
    try {
      await _repository.changePassword(currentPassword, newPassword);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}
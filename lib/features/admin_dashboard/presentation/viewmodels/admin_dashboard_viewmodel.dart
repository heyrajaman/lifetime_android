import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/admin_dashboard_repository.dart';

// Auto-dispose providers so data refreshes when leaving/returning to the screen
final applicantsListProvider =
FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(adminDashboardRepositoryProvider).getApplicants();
});

final membersListProvider =
FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(adminDashboardRepositoryProvider).getMembers();
});

// ViewModel for updating the fee
final feeUpdateViewModelProvider = StateNotifierProvider<
    FeeUpdateViewModel, AsyncValue<void>>((ref) {
  return FeeUpdateViewModel(ref.read(adminDashboardRepositoryProvider));
});

class FeeUpdateViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminDashboardRepository _repository;

  FeeUpdateViewModel(this._repository) : super(const AsyncData(null));

  Future<bool> updateFee(double newAmount) async {
    if (!mounted) return false;

    state = const AsyncLoading();
    try {
      await _repository.updateFee(newAmount);

      if (!mounted) return true;
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      if (!mounted) return true;
      state = AsyncError(e, stack);
      return false;
    }
  }
}

final memberActionProvider = StateNotifierProvider<MemberActionViewModel, AsyncValue<void>>((ref) {
  return MemberActionViewModel(ref.read(adminDashboardRepositoryProvider));
});

class MemberActionViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminDashboardRepository _repository;

  MemberActionViewModel(this._repository) : super(const AsyncData(null));

  Future<bool> toggleStatus(String id) async {
    if (!mounted) return false;

    state = const AsyncLoading();
    try {
      await _repository.toggleMemberStatus(id);
      if (!mounted) return true;

      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      if (!mounted) return false;
      state = AsyncError(e, stack);
      return false;
    }
  }
}
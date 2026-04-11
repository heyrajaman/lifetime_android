import 'package:flutter/material.dart';
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

final statsDateRangeProvider = StateProvider.autoDispose<DateTimeRange?>((ref) => null);

final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repository = ref.read(adminDashboardRepositoryProvider);
  final dateRange = ref.watch(statsDateRangeProvider);

  String? startDateStr;
  String? endDateStr;

  if (dateRange != null) {
    startDateStr = dateRange.start.toIso8601String();
    endDateStr = dateRange.end.toIso8601String();
  }

  return repository.getDashboardStats(startDate: startDateStr, endDate: endDateStr);
});

final exportReportViewModelProvider = StateNotifierProvider<ExportReportViewModel, AsyncValue<void>>((ref) {
  return ExportReportViewModel(ref.read(adminDashboardRepositoryProvider));
});

class ExportReportViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminDashboardRepository _repository;

  ExportReportViewModel(this._repository) : super(const AsyncData(null));

  Future<List<int>?> downloadReport({String? startDate, String? endDate}) async {
    state = const AsyncLoading();
    try {
      final bytes = await _repository.downloadReport(startDate: startDate, endDate: endDate);
      state = const AsyncData(null);
      return bytes;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return null;
    }
  }
}

final regionsListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(adminDashboardRepositoryProvider).getRegionsAdmin();
});

final regionActionProvider = StateNotifierProvider<RegionActionViewModel, AsyncValue<void>>((ref) {
  return RegionActionViewModel(ref.read(adminDashboardRepositoryProvider));
});

class RegionActionViewModel extends StateNotifier<AsyncValue<void>> {
  final AdminDashboardRepository _repository;

  RegionActionViewModel(this._repository) : super(const AsyncData(null));

  Future<bool> addRegion(String name) async {
    state = const AsyncLoading();
    try {
      await _repository.addRegionAdmin(name);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> toggleRegion(String id) async {
    state = const AsyncLoading();
    try {
      await _repository.toggleRegionAdmin(id);
      state = const AsyncData(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }
}
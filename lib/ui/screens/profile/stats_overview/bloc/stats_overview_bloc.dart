import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/repositories/stats_repository.dart';
import 'stats_overview_event.dart';
import 'stats_overview_state.dart';

class StatsOverviewBloc extends Bloc<StatsOverviewEvent, StatsOverviewState> {
  final StatsRepository repository;

  StatsOverviewBloc({required this.repository}) : super(StatsOverviewInitial()) {
    on<StatsOverviewLoadStarted>(_onLoadStarted);
    add(const StatsOverviewLoadStarted());
  }

  Future<void> _onLoadStarted(
    StatsOverviewLoadStarted event,
    Emitter<StatsOverviewState> emit,
  ) async {
    emit(StatsOverviewLoading());
    try {
      final now = DateTime.now();
      final offsetMinutes = now.timeZoneOffset.inMinutes;

      final response = await repository.getStatsOverview(
        clientTimezoneOffset: offsetMinutes,
        limit: 5,
      );
      if (response.success && response.data != null) {
        emit(StatsOverviewSuccess(response.data!));
      } else {
        emit(StatsOverviewFailure(response.message ?? 'Lỗi tải dữ liệu thống kê'));
      }
    } on Failure catch (f) {
      emit(StatsOverviewFailure(f.message.isNotEmpty ? f.message : 'Lỗi tải dữ liệu thống kê'));
    } catch (_) {
      emit(const StatsOverviewFailure('Lỗi tải dữ liệu thống kê'));
    }
  }
}

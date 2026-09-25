import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/report_repository.dart';
import 'report_history_event.dart';
import 'report_history_state.dart';

class ReportHistoryBloc extends Bloc<ReportHistoryEvent, ReportHistoryState> {
  final ReportRepository reportRepository;

  ReportHistoryBloc({required this.reportRepository})
    : super(const ReportHistoryState()) {
    on<ReportHistoryLoaded>(_onLoaded);
    on<ReportHistoryRefreshed>(_onRefreshed);
  }

  Future<void> _onLoaded(
    ReportHistoryLoaded event,
    Emitter<ReportHistoryState> emit,
  ) async {
    emit(state.copyWith(status: ReportHistoryStatus.loading));
    try {
      final response = await reportRepository.getReports(
        page: event.page,
        limit: event.limit,
      );
      if (response.success) {
        emit(
          state.copyWith(
            status: ReportHistoryStatus.success,
            reports: response.data,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ReportHistoryStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportHistoryStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    ReportHistoryRefreshed event,
    Emitter<ReportHistoryState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final response = await reportRepository.getReports(page: 1, limit: 50);
      if (response.success) {
        emit(
          state.copyWith(
            status: ReportHistoryStatus.success,
            reports: response.data,
            isRefreshing: false,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ReportHistoryStatus.failure,
            errorMessage: response.message,
            isRefreshing: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportHistoryStatus.failure,
          errorMessage: e.toString(),
          isRefreshing: false,
        ),
      );
    }
  }
}

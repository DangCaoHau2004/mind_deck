import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/report_error_messages.dart';
import 'package:mind_deck/data/repositories/report_repository.dart';
import 'report_detail_event.dart';
import 'report_detail_state.dart';

class ReportDetailBloc extends Bloc<ReportDetailEvent, ReportDetailState> {
  final ReportRepository reportRepository;

  ReportDetailBloc({required this.reportRepository}) : super(const ReportDetailState()) {
    on<ReportDetailLoaded>(_onLoaded);
  }

  Future<void> _onLoaded(ReportDetailLoaded event, Emitter<ReportDetailState> emit) async {
    emit(state.copyWith(status: ReportDetailStatus.loading));
    try {
      final response = await reportRepository.getReportById(event.reportId);
      if (response.success && response.data != null) {
        emit(state.copyWith(status: ReportDetailStatus.success, report: response.data));
      } else {
        emit(
          state.copyWith(
            status: ReportDetailStatus.failure,
            errorMessage: response.message ?? 'Lỗi không xác định',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportDetailStatus.failure,
          errorMessage: ReportErrorMessages.of0(e, 'Không thể tải chi tiết phản ánh'),
        ),
      );
    }
  }
}

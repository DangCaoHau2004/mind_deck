import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/report_error_messages.dart';
import 'package:mind_deck/data/repositories/image_repository.dart';
import 'package:mind_deck/data/repositories/report_repository.dart';
import 'report_form_event.dart';
import 'report_form_state.dart';

class ReportFormBloc extends Bloc<ReportFormEvent, ReportFormState> {
  final ReportRepository reportRepository;
  final ImageRepository imageRepository;

  ReportFormBloc({required this.reportRepository, required this.imageRepository})
    : super(const ReportFormState()) {
    on<ReportFormSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(ReportFormSubmitted event, Emitter<ReportFormState> emit) async {
    emit(state.copyWith(status: ReportFormStatus.loading));
    try {
      List<String> uploadedUrls = [];

      for (final file in event.images) {
        final uploadRes = await imageRepository.uploadImage(file);
        if (uploadRes.success && uploadRes.data != null) {
          final url = uploadRes.data!['url'] as String? ?? uploadRes.data!['path'] as String? ?? '';
          uploadedUrls.add(url);
        } else {
          emit(
            state.copyWith(
              status: ReportFormStatus.failure,
              errorMessage: uploadRes.message ?? 'Không thể tải ảnh lên',
            ),
          );
          return;
        }
      }

      final reportRes = await reportRepository.createReport(
        type: event.type,
        targetType: event.targetType,
        targetId: event.targetId,
        description: event.description,
        attachments: uploadedUrls,
      );

      if (reportRes.success) {
        emit(
          state.copyWith(
            status: ReportFormStatus.success,
            successMessage: 'Gửi báo cáo thành công!',
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ReportFormStatus.failure,
            errorMessage: reportRes.message ?? 'Không thể gửi báo cáo',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportFormStatus.failure,
          errorMessage: ReportErrorMessages.of0(e, 'Không thể gửi báo cáo'),
        ),
      );
    }
  }
}

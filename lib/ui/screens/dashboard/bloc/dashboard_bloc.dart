import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<DashboardLoadStarted>(_onLoadStarted);
  }

  Future<void> _onLoadStarted(
    DashboardLoadStarted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final timezoneOffset = DateTime.now().timeZoneOffset.inMinutes;
      final response = await repository.getDashboardData(
        timezoneOffset: timezoneOffset,
      );

      if (response.success && response.data != null) {
        emit(DashboardSuccess(data: response.data!));
      } else {
        emit(
          DashboardFailure(
            error: response.message ?? 'Không thể tải dữ liệu trang chủ',
          ),
        );
      }
    } catch (e) {
      emit(DashboardFailure(error: e.toString()));
    }
  }
}

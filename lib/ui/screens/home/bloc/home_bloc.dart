import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/home/home_data_model.dart';
import 'package:mind_deck/data/repositories/home_repository.dart';
import 'package:mind_deck/data/repositories/study_repository.dart';
import 'package:mind_deck/utils/timezone_utils.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository repository;
  final StudyRepository studyRepository;

  HomeBloc({required this.repository, required this.studyRepository}) : super(const HomeState()) {
    on<HomeLoadStarted>(_onLoadStarted);
    on<HomeRefreshed>(_onRefreshed);
    on<HomeContinueSessionDismissed>(_onContinueSessionDismissed);
  }

  /// Bỏ phiên ngay trên giao diện, API chạy ngầm; lỗi thì khôi phục khối và báo bằng toast.
  Future<void> _onContinueSessionDismissed(
    HomeContinueSessionDismissed event,
    Emitter<HomeState> emit,
  ) async {
    final before = state.data;
    if (before == null) return;
    emit(state.copyWith(data: before.withoutContinueSession(event.sessionId)));
    try {
      await studyRepository.deleteSession(event.sessionId);
    } catch (e) {
      emit(_failed(e, status: state.status).copyWith(data: before));
    }
  }

  Future<void> _onLoadStarted(HomeLoadStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final data = await _fetch();
      emit(state.copyWith(status: HomeStatus.success, data: data));
    } catch (e) {
      emit(_failed(e, status: HomeStatus.failure));
    }
  }

  Future<void> _onRefreshed(HomeRefreshed event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isRefreshing: true));
    try {
      final data = await _fetch();
      emit(state.copyWith(status: HomeStatus.success, data: data, isRefreshing: false));
    } catch (e) {
      // Đã có dữ liệu thì giữ nguyên trên màn, chỉ báo lỗi.
      emit(
        _failed(
          e,
          status: state.data != null ? HomeStatus.success : HomeStatus.failure,
        ).copyWith(isRefreshing: false),
      );
    }
  }

  Future<HomeDataModel> _fetch() async {
    final response = await repository.getHomeData(timezone: await localTimezone());
    if (response.success && response.data != null) return response.data!;
    throw UnknownFailure(
      message: AppErrorCodes.loadDataFailed.tr,
      errorCode: AppErrorCodes.loadDataFailed,
    );
  }

  HomeState _failed(Object e, {required HomeStatus status}) {
    final failure = e is Failure ? e : UnknownFailure(message: e.toString());
    return state.copyWith(status: status, failure: failure, failureCount: state.failureCount + 1);
  }
}

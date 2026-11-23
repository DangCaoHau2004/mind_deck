import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/home/home_class_model.dart';
import 'package:mind_deck/data/models/home/home_continue_session_model.dart';
import 'package:mind_deck/data/models/home/home_fsrs_stats_model.dart';
import 'package:mind_deck/data/models/home/home_recent_deck_model.dart';
import 'package:mind_deck/data/models/home/home_user_model.dart';

class HomeDataModel extends Equatable {
  final HomeUserModel user;
  final HomeFsrsStatsModel fsrsStats;
  final List<HomeRecentDeckModel> recentDecks;
  final List<HomeClassModel> classes;

  /// Tổng số lớp của user; `classes` chỉ chứa tối đa 3 lớp.
  final int classesTotal;

  /// Phiên flashcard / bài kiểm tra đang dở (tối đa 3, mới nhất trước).
  final List<HomeContinueSession> continueSessions;

  const HomeDataModel({
    required this.user,
    required this.fsrsStats,
    required this.recentDecks,
    required this.classes,
    this.classesTotal = 0,
    this.continueSessions = const [],
  });

  bool get hasMoreClasses => classesTotal > classes.length;

  /// Khuôn cho skeleton
  factory HomeDataModel.placeholder() => HomeDataModel(
    user: const HomeUserModel(fullName: 'Người dùng', currentStreak: 5, unreadNotifications: 0),
    fsrsStats: const HomeFsrsStatsModel(
      dueTodayCount: 12,
      masteredCount: 40,
      accuracy: 80,
      avgRetrievability: 0.8,
      chart: [],
    ),
    recentDecks: List.filled(
      3,
      const HomeRecentDeckModel(
        id: '',
        name: 'Bộ thẻ mẫu',
        icon: 'default_deck',
        color: '#9E9E9E',
        studiedCards: 5,
        totalCards: 20,
      ),
    ),
    classes: List.filled(2, const HomeClassModel(id: '', name: 'Lớp học mẫu')),
    classesTotal: 2,
  );

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    final classes =
        (json['classes'] as List<dynamic>?)?.map((e) => HomeClassModel.fromJson(e)).toList() ??
        <HomeClassModel>[];
    return HomeDataModel(
      user: HomeUserModel.fromJson(json['user'] ?? {}),
      fsrsStats: HomeFsrsStatsModel.fromJson(json['fsrsStats'] ?? {}),
      recentDecks:
          (json['recentDecks'] as List<dynamic>?)
              ?.map((e) => HomeRecentDeckModel.fromJson(e))
              .toList() ??
          [],
      classes: classes,
      classesTotal: (json['classesTotal'] as num?)?.toInt() ?? classes.length,
      continueSessions: [
        for (final e in json['continueSessions'] as List<dynamic>? ?? [])
          HomeContinueSession.fromJson(e as Map<String, dynamic>),
      ],
    );
  }

  /// Bỏ một phiên khỏi khối "Đang học dở" (người dùng vừa bỏ phiên flashcard).
  HomeDataModel withoutContinueSession(String sessionId) => HomeDataModel(
    user: user,
    fsrsStats: fsrsStats,
    recentDecks: recentDecks,
    classes: classes,
    classesTotal: classesTotal,
    continueSessions: [
      for (final s in continueSessions)
        if (s.sessionId != sessionId) s,
    ],
  );

  @override
  List<Object?> get props => [
    user,
    fsrsStats,
    recentDecks,
    classes,
    classesTotal,
    continueSessions,
  ];
}

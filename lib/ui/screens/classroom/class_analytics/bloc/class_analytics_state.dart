import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_analytics_models.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/page_info.dart';

enum ClassAnalyticsStatus { initial, loading, success, failure }

class ClassAnalyticsState extends Equatable {
  final ClassAnalyticsStatus status;
  final String? errorMessage;
  final bool isRefreshing;
  final bool isTeacher;

  // General Data (chỉ giảng viên)
  final List<ClassMemberModel> members;

  /// Bài giao đang diễn ra / đã kết thúc (mỗi nhóm phân trang riêng, tải thêm khi cuộn ô chọn).
  final List<ClassAssignmentModel> activeAssignments;
  final List<ClassAssignmentModel> historyAssignments;
  final PageInfo membersPage;
  final PageInfo activeAssignmentsPage;
  final PageInfo historyAssignmentsPage;

  // Selections
  final ClassMemberModel? selectedMember;
  final ClassAssignmentModel? selectedAssignment;

  // Class Overview Data (chỉ giảng viên)
  final List<AssignmentProgressModel> assignmentProgress;
  final ScoreDistribution? scoreDistribution;
  final DeckHealthResponse? classDeckHealth;
  final List<HardestCardModel> classHardestCards;

  // Personal Data (giảng viên: học viên đang chọn; học viên: chính mình)
  final DeckHealthResponse? personalDeckHealth;
  final List<HardestCardModel> personalHardestCards;
  final List<ReviewWorkloadModel> personalReviewWorkload;
  final List<StudentAssignmentResult> personalAssignments;

  const ClassAnalyticsState({
    this.status = ClassAnalyticsStatus.initial,
    this.errorMessage,
    this.isRefreshing = false,
    this.isTeacher = false,
    this.members = const [],
    this.activeAssignments = const [],
    this.historyAssignments = const [],
    this.membersPage = const PageInfo(),
    this.activeAssignmentsPage = const PageInfo(),
    this.historyAssignmentsPage = const PageInfo(),
    this.selectedMember,
    this.selectedAssignment,
    this.assignmentProgress = const [],
    this.scoreDistribution,
    this.classDeckHealth,
    this.classHardestCards = const [],
    this.personalDeckHealth,
    this.personalHardestCards = const [],
    this.personalReviewWorkload = const [],
    this.personalAssignments = const [],
  });

  /// Mọi bài giao đã tải: đang diễn ra trước, đã kết thúc sau.
  List<ClassAssignmentModel> get assignments => [...activeAssignments, ...historyAssignments];

  /// Còn trang bài giao chưa tải (ở nhóm nào cũng được).
  bool get hasMoreAssignments => activeAssignmentsPage.hasMore || historyAssignmentsPage.hasMore;

  ClassAnalyticsState copyWith({
    ClassAnalyticsStatus? status,
    String? errorMessage,
    bool? isRefreshing,
    bool? isTeacher,
    List<ClassMemberModel>? members,
    List<ClassAssignmentModel>? activeAssignments,
    List<ClassAssignmentModel>? historyAssignments,
    PageInfo? membersPage,
    PageInfo? activeAssignmentsPage,
    PageInfo? historyAssignmentsPage,
    ClassMemberModel? selectedMember,
    ClassAssignmentModel? selectedAssignment,
    List<AssignmentProgressModel>? assignmentProgress,
    ScoreDistribution? scoreDistribution,
    bool clearScoreDistribution = false,
    DeckHealthResponse? classDeckHealth,
    List<HardestCardModel>? classHardestCards,
    DeckHealthResponse? personalDeckHealth,
    List<HardestCardModel>? personalHardestCards,
    List<ReviewWorkloadModel>? personalReviewWorkload,
    List<StudentAssignmentResult>? personalAssignments,
  }) {
    return ClassAnalyticsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isTeacher: isTeacher ?? this.isTeacher,
      members: members ?? this.members,
      activeAssignments: activeAssignments ?? this.activeAssignments,
      historyAssignments: historyAssignments ?? this.historyAssignments,
      membersPage: membersPage ?? this.membersPage,
      activeAssignmentsPage: activeAssignmentsPage ?? this.activeAssignmentsPage,
      historyAssignmentsPage: historyAssignmentsPage ?? this.historyAssignmentsPage,
      selectedMember: selectedMember ?? this.selectedMember,
      selectedAssignment: selectedAssignment ?? this.selectedAssignment,
      assignmentProgress: assignmentProgress ?? this.assignmentProgress,
      scoreDistribution: clearScoreDistribution
          ? null
          : (scoreDistribution ?? this.scoreDistribution),
      classDeckHealth: classDeckHealth ?? this.classDeckHealth,
      classHardestCards: classHardestCards ?? this.classHardestCards,
      personalDeckHealth: personalDeckHealth ?? this.personalDeckHealth,
      personalHardestCards: personalHardestCards ?? this.personalHardestCards,
      personalReviewWorkload: personalReviewWorkload ?? this.personalReviewWorkload,
      personalAssignments: personalAssignments ?? this.personalAssignments,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    isRefreshing,
    isTeacher,
    members,
    activeAssignments,
    historyAssignments,
    membersPage,
    activeAssignmentsPage,
    historyAssignmentsPage,
    selectedMember,
    selectedAssignment,
    assignmentProgress,
    scoreDistribution,
    classDeckHealth,
    classHardestCards,
    personalDeckHealth,
    personalHardestCards,
    personalReviewWorkload,
    personalAssignments,
  ];
}

import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_analytics_models.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';

enum ClassAnalyticsStatus { initial, loading, success, failure }

class ClassAnalyticsState extends Equatable {
  final ClassAnalyticsStatus status;
  final String? errorMessage;
  final bool isRefreshing;
  final bool isTeacher;

  // General Data (chỉ giảng viên)
  final List<ClassMemberModel> members;
  final List<ClassAssignmentModel> assignments;

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
    this.assignments = const [],
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

  ClassAnalyticsState copyWith({
    ClassAnalyticsStatus? status,
    String? errorMessage,
    bool? isRefreshing,
    bool? isTeacher,
    List<ClassMemberModel>? members,
    List<ClassAssignmentModel>? assignments,
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
      assignments: assignments ?? this.assignments,
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
    assignments,
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

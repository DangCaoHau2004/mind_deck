import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_analytics_models.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';

enum ClassAnalyticsStatus { initial, loading, success, failure }

class ClassAnalyticsState extends Equatable {
  final ClassAnalyticsStatus status;
  final String? errorMessage;
  final bool isRefreshing;

  // General Data
  final List<ClassMemberModel> members;
  final List<ClassAssignmentModel> assignments;

  // Selections
  final ClassMemberModel? selectedMember;
  final ClassAssignmentModel? selectedAssignment;

  // Class Overview Data
  final List<AssignmentProgressModel> assignmentProgress;
  final List<DeckHealthModel> classDeckHealth;
  final List<HardestCardModel> classHardestCards;

  // Personal Data
  final List<DeckHealthModel> personalDeckHealth;
  final List<HardestCardModel> personalHardestCards;
  final List<ReviewWorkloadModel> personalReviewWorkload;

  const ClassAnalyticsState({
    this.status = ClassAnalyticsStatus.initial,
    this.errorMessage,
    this.isRefreshing = false,
    this.members = const [],
    this.assignments = const [],
    this.selectedMember,
    this.selectedAssignment,
    this.assignmentProgress = const [],
    this.classDeckHealth = const [],
    this.classHardestCards = const [],
    this.personalDeckHealth = const [],
    this.personalHardestCards = const [],
    this.personalReviewWorkload = const [],
  });

  ClassAnalyticsState copyWith({
    ClassAnalyticsStatus? status,
    String? errorMessage,
    bool? isRefreshing,
    List<ClassMemberModel>? members,
    List<ClassAssignmentModel>? assignments,
    ClassMemberModel? selectedMember,
    ClassAssignmentModel? selectedAssignment,
    List<AssignmentProgressModel>? assignmentProgress,
    List<DeckHealthModel>? classDeckHealth,
    List<HardestCardModel>? classHardestCards,
    List<DeckHealthModel>? personalDeckHealth,
    List<HardestCardModel>? personalHardestCards,
    List<ReviewWorkloadModel>? personalReviewWorkload,
  }) {
    return ClassAnalyticsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      members: members ?? this.members,
      assignments: assignments ?? this.assignments,
      selectedMember: selectedMember ?? this.selectedMember,
      selectedAssignment: selectedAssignment ?? this.selectedAssignment,
      assignmentProgress: assignmentProgress ?? this.assignmentProgress,
      classDeckHealth: classDeckHealth ?? this.classDeckHealth,
      classHardestCards: classHardestCards ?? this.classHardestCards,
      personalDeckHealth: personalDeckHealth ?? this.personalDeckHealth,
      personalHardestCards: personalHardestCards ?? this.personalHardestCards,
      personalReviewWorkload: personalReviewWorkload ?? this.personalReviewWorkload,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    isRefreshing,
    members,
    assignments,
    selectedMember,
    selectedAssignment,
    assignmentProgress,
    classDeckHealth,
    classHardestCards,
    personalDeckHealth,
    personalHardestCards,
    personalReviewWorkload,
  ];
}

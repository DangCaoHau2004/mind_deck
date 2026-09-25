import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_model.dart';

enum ClassHubStatus { initial, loading, success, failure }

class ClassHubState extends Equatable {
  final ClassHubStatus status;
  final ClassModel? classModel;
  final String? errorMessage;

  // Custom metrics for Hub
  final int pendingCount;
  final int totalScore;
  final int rank;

  const ClassHubState({
    this.status = ClassHubStatus.initial,
    this.classModel,
    this.errorMessage,
    this.pendingCount = 0,
    this.totalScore = 0,
    this.rank = 0,
  });

  ClassHubState copyWith({
    ClassHubStatus? status,
    ClassModel? classModel,
    String? errorMessage,
    int? pendingCount,
    int? totalScore,
    int? rank,
  }) {
    return ClassHubState(
      status: status ?? this.status,
      classModel: classModel ?? this.classModel,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingCount: pendingCount ?? this.pendingCount,
      totalScore: totalScore ?? this.totalScore,
      rank: rank ?? this.rank,
    );
  }

  @override
  List<Object?> get props => [status, classModel, errorMessage, pendingCount, totalScore, rank];
}

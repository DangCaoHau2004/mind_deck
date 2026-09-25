import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';

enum ClassMembersStatus { initial, loading, success, failure }

class ClassMembersState extends Equatable {
  final ClassMembersStatus status;
  final List<ClassMemberModel> members;
  final List<ClassMemberModel> pendingMembers;
  final String? errorMessage;

  // Hành động xử lý
  final bool isProcessing;
  final bool isRefreshing;
  final String? processErrorMessage;

  const ClassMembersState({
    this.status = ClassMembersStatus.initial,
    this.members = const [],
    this.pendingMembers = const [],
    this.errorMessage,
    this.isProcessing = false,
    this.isRefreshing = false,
    this.processErrorMessage,
  });

  ClassMembersState copyWith({
    ClassMembersStatus? status,
    List<ClassMemberModel>? members,
    List<ClassMemberModel>? pendingMembers,
    String? errorMessage,
    bool? isProcessing,
    bool? isRefreshing,
    String? processErrorMessage,
  }) {
    return ClassMembersState(
      status: status ?? this.status,
      members: members ?? this.members,
      pendingMembers: pendingMembers ?? this.pendingMembers,
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      processErrorMessage: processErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    members,
    pendingMembers,
    errorMessage,
    isProcessing,
    isRefreshing,
    processErrorMessage,
  ];
}

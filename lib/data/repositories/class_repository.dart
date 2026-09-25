import 'package:mind_deck/data/data_sources/remote/class_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/class/class_material_response_model.dart';
import 'package:mind_deck/data/models/class/class_leaderboard_response_model.dart';
import 'package:mind_deck/data/models/class/class_analytics_models.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_submission_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class ClassRepository {
  // Class management
  Future<ApiListResponse<ClassModel>> getClasses();
  Future<ApiResponse<ClassModel>> getClassById(String classId);
  Future<ApiResponse<ClassModel>> createClass({
    required String name,
    String? description,
    bool requireApproval = false,
    bool isPublic = false,
  });
  Future<ApiResponse<void>> updateClass(
    String classId, {
    required String name,
    String? description,
    bool requireApproval = false,
    bool isPublic = false,
  });
  Future<ApiResponse<void>> deleteClass(String classId);
  Future<ApiResponse<ClassModel>> joinClass({required String classId, required String joinCode});
  Future<ApiResponse<ClassModel>> previewClass(String code);
  Future<ApiResponse<void>> approveMember(String classId, String userId);
  Future<ApiResponse<void>> kickMember(String classId, String userId);
  Future<ApiResponse<void>> updateMemberRole(String classId, String userId, String role);
  Future<ApiListResponse<ClassMemberModel>> getPendingMembers(String classId);
  Future<ApiListResponse<ClassMemberModel>> getMembers(String classId);
  Future<ApiResponse<void>> addMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  });
  Future<ApiResponse<void>> deleteMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  });
  Future<ApiResponse<ClassMaterialResponseModel>> getMaterials(
    String classId, {
    int page = 1,
    int limit = 20,
    String? search,
  });
  Future<ApiResponse<void>> cloneClassMaterials(
    String classId, {
    required String folderId,
    required String deckId,
  });

  // Assignments
  Future<ApiResponse<ClassAssignmentModel>> createAssignment(
    String classId, {
    required String title,
    String? description,
    required AssignmentType type,
    String? deckId,
    String? testId,
    required String deadline,
  });
  Future<ApiResponse<void>> updateAssignment(
    String classId,
    String assignmentId, {
    required String title,
    String? description,
    required String deadline,
  });
  Future<ApiResponse<void>> deleteAssignment(String classId, String assignmentId);
  Future<ApiListResponse<ClassAssignmentModel>> getAssignments(
    String classId, {
    String tab = 'active',
  });
  Future<ApiResponse<ClassAssignmentSubmissionModel>> submitAssignmentTest(
    String classId,
    String assignmentId, {
    String? testId,
    required int totalQuestions,
    required int correctAnswers,
    required int durationMs,
    String? startedAt,
    String? completedAt,
    List<Map<String, dynamic>>? answers,
  });
  Future<ApiListResponse<ClassAssignmentSubmissionModel>> getSubmissions(
    String classId,
    String assignmentId,
  );
  Future<ApiListResponse<ClassAssignmentSubmissionModel>> getMySubmissions(String classId);
  Future<ApiListResponse<ClassAssignmentSubmissionModel>> getOverdueAssignments(String classId);
  Future<ApiResponse<ClassLeaderboardResponseModel>> getLeaderboard(String classId);

  // Analytics
  Future<ApiListResponse<ReviewWorkloadModel>> getReviewWorkload(
    String classId, {
    String? studentId,
    String? timezone,
  });
  Future<ApiListResponse<HardestCardModel>> getHardestCards(String classId, {String? studentId});
  Future<ApiListResponse<DeckHealthModel>> getDeckHealth(
    String classId, {
    String? deckId,
    String? studentId,
  });
  Future<ApiListResponse<AssignmentProgressModel>> getAssignmentProgress(
    String classId,
    String assignmentId,
  );
  Future<ApiListResponse<AssignmentDrillDownModel>> getAssignmentDrillDown(
    String classId,
    String assignmentId, {
    String? status,
  });
}

class ClassRepositoryImpl with ApiHandler implements ClassRepository {
  final ClassRemoteDataSource remoteDataSource;

  ClassRepositoryImpl({required this.remoteDataSource});

  // Class management
  @override
  Future<ApiListResponse<ClassModel>> getClasses() async {
    return executeApi(() async {
      final response = await remoteDataSource.getClasses();
      return ApiListResponse<ClassModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<ClassModel>> getClassById(String classId) async {
    return executeApi(() async {
      final response = await remoteDataSource.getClassById(classId);
      return ApiResponse<ClassModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<ClassModel>> createClass({
    required String name,
    String? description,
    bool requireApproval = false,
    bool isPublic = false,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.createClass(
        name: name,
        description: description,
        requireApproval: requireApproval,
        isPublic: isPublic,
      );
      return ApiResponse<ClassModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> updateClass(
    String classId, {
    required String name,
    String? description,
    bool requireApproval = false,
    bool isPublic = false,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.updateClass(
        classId,
        name: name,
        description: description,
        requireApproval: requireApproval,
        isPublic: isPublic,
      );
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> deleteClass(String classId) async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteClass(classId);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<ClassModel>> joinClass({
    required String classId,
    required String joinCode,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.joinClass(classId: classId, joinCode: joinCode);
      return ApiResponse<ClassModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<ClassModel>> previewClass(String code) async {
    return executeApi(() async {
      final response = await remoteDataSource.previewClass(code);
      return ApiResponse<ClassModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> approveMember(String classId, String userId) async {
    return executeApi(() async {
      final response = await remoteDataSource.approveMember(classId, userId);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> kickMember(String classId, String userId) async {
    return executeApi(() async {
      final response = await remoteDataSource.kickMember(classId, userId);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> updateMemberRole(String classId, String userId, String role) async {
    return executeApi(() async {
      final response = await remoteDataSource.updateMemberRole(classId, userId, role);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiListResponse<ClassMemberModel>> getPendingMembers(String classId) async {
    return executeApi(() async {
      final response = await remoteDataSource.getPendingMembers(classId);
      return ApiListResponse<ClassMemberModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassMemberModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<ClassMemberModel>> getMembers(String classId) async {
    return executeApi(() async {
      final response = await remoteDataSource.getMembers(classId);
      return ApiListResponse<ClassMemberModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassMemberModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> addMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.addMaterials(
        classId,
        folderIds: folderIds,
        deckIds: deckIds,
      );
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> deleteMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteMaterials(
        classId,
        folderIds: folderIds,
        deckIds: deckIds,
      );
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<ClassMaterialResponseModel>> getMaterials(
    String classId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getMaterials(
        classId,
        page: page,
        limit: limit,
        search: search,
      );
      return ApiResponse<ClassMaterialResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassMaterialResponseModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> cloneClassMaterials(
    String classId, {
    required String folderId,
    required String deckId,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.cloneClassMaterials(
        classId,
        folderId: folderId,
        deckId: deckId,
      );
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  // Assignments
  @override
  Future<ApiResponse<ClassAssignmentModel>> createAssignment(
    String classId, {
    required String title,
    String? description,
    required AssignmentType type,
    String? deckId,
    String? testId,
    required String deadline,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.createAssignment(
        classId,
        title: title,
        description: description,
        type: type.toJson(),
        deckId: deckId,
        testId: testId,
        deadline: deadline,
      );
      return ApiResponse<ClassAssignmentModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassAssignmentModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> updateAssignment(
    String classId,
    String assignmentId, {
    required String title,
    String? description,
    required String deadline,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.updateAssignment(
        classId,
        assignmentId,
        title: title,
        description: description,
        deadline: deadline,
      );
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> deleteAssignment(String classId, String assignmentId) async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteAssignment(classId, assignmentId);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiListResponse<ClassAssignmentModel>> getAssignments(
    String classId, {
    String tab = 'active',
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getAssignments(classId, tab: tab);
      return ApiListResponse<ClassAssignmentModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassAssignmentModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<ClassAssignmentSubmissionModel>> submitAssignmentTest(
    String classId,
    String assignmentId, {
    String? testId,
    required int totalQuestions,
    required int correctAnswers,
    required int durationMs,
    String? startedAt,
    String? completedAt,
    List<Map<String, dynamic>>? answers,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.submitAssignmentTest(
        classId,
        assignmentId,
        testId: testId,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        durationMs: durationMs,
        startedAt: startedAt,
        completedAt: completedAt,
        answers: answers,
      );
      return ApiResponse<ClassAssignmentSubmissionModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassAssignmentSubmissionModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<ClassAssignmentSubmissionModel>> getSubmissions(
    String classId,
    String assignmentId,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.getSubmissions(classId, assignmentId);
      return ApiListResponse<ClassAssignmentSubmissionModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassAssignmentSubmissionModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<ClassAssignmentSubmissionModel>> getMySubmissions(String classId) async {
    return executeApi(() async {
      final response = await remoteDataSource.getMySubmissions(classId);
      return ApiListResponse<ClassAssignmentSubmissionModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassAssignmentSubmissionModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<ClassAssignmentSubmissionModel>> getOverdueAssignments(
    String classId,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.getOverdueAssignments(classId);
      return ApiListResponse<ClassAssignmentSubmissionModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassAssignmentSubmissionModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<ClassLeaderboardResponseModel>> getLeaderboard(String classId) async {
    return executeApi(() async {
      final response = await remoteDataSource.getLeaderboard(classId);
      return ApiResponse<ClassLeaderboardResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassLeaderboardResponseModel.fromJson(json),
      );
    });
  }

  // Analytics
  @override
  Future<ApiListResponse<ReviewWorkloadModel>> getReviewWorkload(
    String classId, {
    String? studentId,
    String? timezone,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getReviewWorkload(
        classId,
        studentId: studentId,
        timezone: timezone,
      );
      return ApiListResponse<ReviewWorkloadModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ReviewWorkloadModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<HardestCardModel>> getHardestCards(
    String classId, {
    String? studentId,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getHardestCards(classId, studentId: studentId);
      return ApiListResponse<HardestCardModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => HardestCardModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<DeckHealthModel>> getDeckHealth(
    String classId, {
    String? deckId,
    String? studentId,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getDeckHealth(
        classId,
        deckId: deckId,
        studentId: studentId,
      );
      return ApiListResponse<DeckHealthModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DeckHealthModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<AssignmentProgressModel>> getAssignmentProgress(
    String classId,
    String assignmentId,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.getAssignmentProgress(classId, assignmentId);
      return ApiListResponse<AssignmentProgressModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AssignmentProgressModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<AssignmentDrillDownModel>> getAssignmentDrillDown(
    String classId,
    String assignmentId, {
    String? status,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getAssignmentDrillDown(
        classId,
        assignmentId,
        status: status,
      );
      return ApiListResponse<AssignmentDrillDownModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AssignmentDrillDownModel.fromJson(json),
      );
    });
  }
}

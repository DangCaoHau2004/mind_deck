import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class ClassRemoteDataSource {
  // Class management
  Future<Response> getClasses();
  Future<Response> getClassById(String classId);
  Future<Response> createClass({
    required String name,
    String? description,
    bool requireApproval = false,
    bool isPublic = false,
  });
  Future<Response> updateClass(
    String classId, {
    required String name,
    String? description,
    bool requireApproval = false,
    bool isPublic = false,
  });
  Future<Response> deleteClass(String classId);
  Future<Response> joinClass({required String classId, required String joinCode});
  Future<Response> previewClass(String code);
  Future<Response> approveMember(String classId, String userId);
  Future<Response> kickMember(String classId, String userId);
  Future<Response> updateMemberRole(String classId, String userId, String role);
  Future<Response> getPendingMembers(String classId);
  Future<Response> getMembers(String classId);
  Future<Response> addMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  });
  Future<Response> deleteMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  });
  Future<Response> getMaterials(String classId, {int page = 1, int limit = 20, String? search});
  Future<Response> cloneClassMaterials(
    String classId, {
    required String folderId,
    required String deckId,
  });

  // Assignments
  Future<Response> createAssignment(
    String classId, {
    required String title,
    String? description,
    required String type,
    String? deckId,
    String? testId,
    required String deadline,
  });
  Future<Response> updateAssignment(
    String classId,
    String assignmentId, {
    required String title,
    String? description,
    required String deadline,
  });
  Future<Response> deleteAssignment(String classId, String assignmentId);
  Future<Response> getAssignments(String classId, {String tab = 'active'});
  Future<Response> submitAssignmentTest(
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
  Future<Response> getSubmissions(String classId, String assignmentId);
  Future<Response> getMySubmissions(String classId);
  Future<Response> getOverdueAssignments(String classId);
  Future<Response> getLeaderboard(String classId);

  // Analytics
  Future<Response> getReviewWorkload(String classId, {String? studentId, String? timezone});
  Future<Response> getHardestCards(String classId, {String? studentId});
  Future<Response> getDeckHealth(String classId, {String? deckId, String? studentId});
  Future<Response> getAssignmentProgress(String classId, String assignmentId);
  Future<Response> getAssignmentDrillDown(String classId, String assignmentId, {String? status});
}

class ClassRemoteDataSourceImpl implements ClassRemoteDataSource {
  final Dio dio;

  ClassRemoteDataSourceImpl({required this.dio});

  // Class management
  @override
  Future<Response> getClasses() {
    return dio.get(ApiEndpoints.classes);
  }

  @override
  Future<Response> getClassById(String classId) {
    return dio.get('${ApiEndpoints.classes}/$classId');
  }

  @override
  Future<Response> createClass({
    required String name,
    String? description,
    bool requireApproval = false,
    bool isPublic = false,
  }) {
    return dio.post(
      ApiEndpoints.classes,
      data: {
        'name': name,
        'description': ?description,
        'requireApproval': requireApproval,
        'isPublic': isPublic,
      },
    );
  }

  @override
  Future<Response> updateClass(
    String classId, {
    required String name,
    String? description,
    bool requireApproval = false,
    bool isPublic = false,
  }) {
    return dio.put(
      '${ApiEndpoints.classes}/$classId',
      data: {
        'name': name,
        'description': ?description,
        'requireApproval': requireApproval,
        'isPublic': isPublic,
      },
    );
  }

  @override
  Future<Response> deleteClass(String classId) {
    return dio.delete('${ApiEndpoints.classes}/$classId');
  }

  @override
  Future<Response> joinClass({required String classId, required String joinCode}) {
    return dio.post(ApiEndpoints.classesJoin, data: {'join_code': joinCode, 'class_id': classId});
  }

  @override
  Future<Response> previewClass(String code) {
    return dio.get('${ApiEndpoints.classes}/preview', queryParameters: {'code': code});
  }

  @override
  Future<Response> approveMember(String classId, String userId) {
    return dio.patch('${ApiEndpoints.classApproveMember}/$classId/members/$userId/approve');
  }

  @override
  Future<Response> kickMember(String classId, String userId) {
    return dio.delete('${ApiEndpoints.classKickMember}/$classId/members/$userId');
  }

  @override
  Future<Response> updateMemberRole(String classId, String userId, String role) {
    return dio.patch('${ApiEndpoints.classes}/$classId/members/$userId/role', data: {'role': role});
  }

  @override
  Future<Response> getPendingMembers(String classId) {
    return dio.get('${ApiEndpoints.classMembersPending}$classId/members/pending');
  }

  @override
  Future<Response> getMembers(String classId) {
    return dio.get('${ApiEndpoints.classMembers}$classId/members');
  }

  @override
  Future<Response> addMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  }) {
    return dio.post(
      '${ApiEndpoints.classMaterials}$classId/materials',
      data: {'folder_ids': folderIds, 'deck_ids': deckIds},
    );
  }

  @override
  Future<Response> deleteMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  }) {
    return dio.delete(
      '${ApiEndpoints.classMaterials}$classId/materials',
      data: {'folder_ids': folderIds, 'deck_ids': deckIds},
    );
  }

  @override
  Future<Response> getMaterials(String classId, {int page = 1, int limit = 20, String? search}) {
    return dio.get(
      '${ApiEndpoints.classMaterials}$classId/materials',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
  }

  @override
  Future<Response> cloneClassMaterials(
    String classId, {
    required String folderId,
    required String deckId,
  }) {
    return dio.post(
      '${ApiEndpoints.classClone}$classId/clone',
      data: {'folderId': folderId, 'deckId': deckId},
    );
  }

  // Assignments
  @override
  Future<Response> createAssignment(
    String classId, {
    required String title,
    String? description,
    required String type,
    String? deckId,
    String? testId,
    required String deadline,
  }) {
    return dio.post(
      '${ApiEndpoints.classAssignments}$classId/assignments',
      data: {
        'title': title,
        'description': ?description,
        'type': type,
        'deckId': ?deckId,
        'testId': ?testId,
        'deadline': deadline,
      },
    );
  }

  @override
  Future<Response> updateAssignment(
    String classId,
    String assignmentId, {
    required String title,
    String? description,
    required String deadline,
  }) {
    return dio.put(
      '${ApiEndpoints.classes}/$classId/assignments/$assignmentId',
      data: {'title': title, 'description': ?description, 'deadline': deadline},
    );
  }

  @override
  Future<Response> deleteAssignment(String classId, String assignmentId) {
    return dio.delete('${ApiEndpoints.classes}/$classId/assignments/$assignmentId');
  }

  @override
  Future<Response> getAssignments(String classId, {String tab = 'active'}) {
    return dio.get(
      '${ApiEndpoints.classAssignments}$classId/assignments',
      queryParameters: {'tab': tab},
    );
  }

  @override
  Future<Response> submitAssignmentTest(
    String classId,
    String assignmentId, {
    String? testId,
    required int totalQuestions,
    required int correctAnswers,
    required int durationMs,
    String? startedAt,
    String? completedAt,
    List<Map<String, dynamic>>? answers,
  }) {
    return dio.post(
      '${ApiEndpoints.classSubmitAssignment}$classId/assignments/$assignmentId/submit',
      data: {
        'testId': ?testId,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'durationMs': durationMs,
        'startedAt': ?startedAt,
        'completedAt': ?completedAt,
        'answers': ?answers,
      },
    );
  }

  @override
  Future<Response> getSubmissions(String classId, String assignmentId) {
    return dio.get(
      '${ApiEndpoints.classAssignmentSubmissions}$classId/assignments/$assignmentId/submissions',
    );
  }

  @override
  Future<Response> getMySubmissions(String classId) {
    return dio.get('${ApiEndpoints.classMySubmissions}$classId/my-submissions');
  }

  @override
  Future<Response> getOverdueAssignments(String classId) {
    return dio.get('${ApiEndpoints.classAssignments}$classId/assignments/overdue');
  }

  @override
  Future<Response> getLeaderboard(String classId) {
    return dio.get('${ApiEndpoints.classLeaderboard}$classId/leaderboard');
  }

  // Analytics
  @override
  Future<Response> getReviewWorkload(String classId, {String? studentId, String? timezone}) {
    return dio.get(
      '${ApiEndpoints.analyticsReviewWorkload}$classId/review-workload',
      queryParameters: {'student_id': ?studentId, 'timezone': ?timezone},
    );
  }

  @override
  Future<Response> getHardestCards(String classId, {String? studentId}) {
    return dio.get(
      '${ApiEndpoints.analyticsHardestCards}$classId/hardest-cards',
      queryParameters: {'student_id': ?studentId},
    );
  }

  @override
  Future<Response> getDeckHealth(String classId, {String? deckId, String? studentId}) {
    return dio.get(
      '${ApiEndpoints.analyticsDeckHealth}$classId/deck-health',
      queryParameters: {'deck_id': ?deckId, 'student_id': ?studentId},
    );
  }

  @override
  Future<Response> getAssignmentProgress(String classId, String assignmentId) {
    return dio.get(
      '${ApiEndpoints.analyticsAssignmentProgress}$classId/assignments/$assignmentId/progress',
    );
  }

  @override
  Future<Response> getAssignmentDrillDown(String classId, String assignmentId, {String? status}) {
    return dio.get(
      '${ApiEndpoints.analyticsAssignmentDrillDown}$classId/assignments/$assignmentId/drill-down',
      queryParameters: {'status': ?status},
    );
  }
}

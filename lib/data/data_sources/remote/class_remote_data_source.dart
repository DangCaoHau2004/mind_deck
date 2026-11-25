import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class ClassRemoteDataSource {
  // Class management
  Future<Response> getClasses({int page = 1, int limit = 20});
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
  Future<Response> deleteClass(String classId, {String? reason});

  /// Gửi `joinCode` HOẶC `classId` (lớp công khai). Gửi cả hai thì BE dùng `joinCode`.
  Future<Response> joinClass({String? joinCode, String? classId});
  Future<Response> previewClass(String code);
  Future<Response> approveMember(String classId, String userId);

  /// Một endpoint cho 3 việc theo trạng thái của `userId`: từ chối (pending), thu hồi lời mời
  /// (invited) hoặc đuổi (approved).
  Future<Response> kickMember(String classId, String userId);
  Future<Response> updateMemberRole(String classId, String userId, String role);
  Future<Response> getPendingMembers(
    String classId, {
    String status = 'pending',
    int page = 1,
    int limit = 20,
  });
  Future<Response> getMembers(String classId, {int page = 1, int limit = 20});
  Future<Response> leaveClass(String classId);

  /// Chỉ chủ lớp: người nhận phải là thành viên đã duyệt. Chủ cũ xuống làm admin.
  Future<Response> transferOwner(String classId, String userId);

  /// Học viên hủy yêu cầu xin vào lớp đang chờ duyệt của chính mình.
  Future<Response> cancelMyJoinRequest(String classId);
  Future<Response> patchClassSettings(String classId, Map<String, dynamic> body);
  Future<Response> patchMyNotifications(String classId, Map<String, dynamic> body);

  // Invitations
  Future<Response> getInvitations({int page = 1, int limit = 20});
  Future<Response> lookupInvites(String classId, List<String> emails);
  Future<Response> sendInvites(String classId, List<String> emails);
  Future<Response> revokeInvite(String classId, String userId);
  Future<Response> acceptInvite(String classId);
  Future<Response> declineInvite(String classId);

  // Materials
  Future<Response> addMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
    String? duplicatePolicy,
  });
  Future<Response> checkMaterials(
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
  Future<Response> getFolderDecks(
    String classId,
    String folderId, {
    int page = 1,
    int limit = 20,
    String? search,
  });
  Future<Response> cloneClassMaterials(
    String classId, {
    required String targetType,
    required String targetId,
  });

  // Assignments
  /// Thời gian được đổi sang UTC ISO-8601 trước khi gửi (BE yêu cầu có múi giờ).
  Future<Response> createAssignment(
    String classId, {
    required String title,
    String? description,
    required String type,
    DateTime? startAt,
    required DateTime endAt,
    String? mode,
    String? scope,
    int? targetCount,
    List<Map<String, dynamic>>? sources,
    String? testId,
  });

  /// Nhận mọi trường của POST trừ `type`. Gửi cả form với giá trị y nguyên là an toàn.
  Future<Response> updateAssignment(
    String classId,
    String assignmentId, {
    required String title,
    String? description,
    DateTime? startAt,
    required DateTime endAt,
    String? mode,
    String? scope,
    int? targetCount,
    List<Map<String, dynamic>>? sources,
    String? testId,
  });
  Future<Response> deleteAssignment(String classId, String assignmentId);
  Future<Response> getAssignments(
    String classId, {
    String tab = 'active',
    int page = 1,
    int limit = 20,
  });
  Future<Response> getSubmissions(
    String classId,
    String assignmentId, {
    int page = 1,
    int limit = 20,
  });
  Future<Response> getMySubmissions(String classId, {int page = 1, int limit = 20});
  Future<Response> getOverdueAssignments(String classId, {int page = 1, int limit = 20});
  Future<Response> getLeaderboard(String classId, {String? month, int limit = 10});

  // Analytics
  Future<Response> getReviewWorkload(String classId, {String? studentId, String? timezone});
  Future<Response> getHardestCards(String classId, {String? studentId});
  Future<Response> getDeckHealth(String classId, {String? deckId, String? studentId});
  Future<Response> getAssignmentProgress(String classId, String assignmentId);
  Future<Response> getAssignmentDrillDown(
    String classId,
    String assignmentId, {
    required String status,
  });
  Future<Response> getScoreDistribution(String classId, String assignmentId);
  Future<Response> getStudentAttempts(String classId, String assignmentId, String userId);
  Future<Response> getAttemptDetail(String classId, String attemptId);
  Future<Response> getStudentAssignments(String classId, String userId);
}

class ClassRemoteDataSourceImpl implements ClassRemoteDataSource {
  final Dio dio;

  ClassRemoteDataSourceImpl({required this.dio});

  // Class management
  @override
  Future<Response> getClasses({int page = 1, int limit = 20}) {
    return dio.get(ApiEndpoints.classes, queryParameters: {'page': page, 'limit': limit});
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
  Future<Response> deleteClass(String classId, {String? reason}) {
    // DELETE mang body JSON (lý do tùy chọn).
    return dio.delete(
      '${ApiEndpoints.classes}/$classId',
      data: {if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim()},
    );
  }

  @override
  Future<Response> joinClass({String? joinCode, String? classId}) {
    return dio.post(ApiEndpoints.classesJoin, data: {'joinCode': ?joinCode, 'classId': ?classId});
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
  Future<Response> getPendingMembers(
    String classId, {
    String status = 'pending',
    int page = 1,
    int limit = 20,
  }) {
    return dio.get(
      '${ApiEndpoints.classMembersPending}$classId/members/pending',
      queryParameters: {'status': status, 'page': page, 'limit': limit},
    );
  }

  @override
  Future<Response> getMembers(String classId, {int page = 1, int limit = 20}) {
    return dio.get(
      '${ApiEndpoints.classMembers}$classId/members',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  @override
  Future<Response> leaveClass(String classId) {
    return dio.post('${ApiEndpoints.classLeave}$classId/leave');
  }

  @override
  Future<Response> transferOwner(String classId, String userId) {
    return dio.post('${ApiEndpoints.classes}/$classId/transfer-owner', data: {'userId': userId});
  }

  @override
  Future<Response> cancelMyJoinRequest(String classId) {
    return dio.delete('${ApiEndpoints.classes}/$classId/requests/me');
  }

  @override
  Future<Response> patchClassSettings(String classId, Map<String, dynamic> body) {
    return dio.patch('${ApiEndpoints.classSettings}$classId/settings', data: body);
  }

  @override
  Future<Response> patchMyNotifications(String classId, Map<String, dynamic> body) {
    return dio.patch(
      '${ApiEndpoints.classMyNotifications}$classId/members/me/notifications',
      data: body,
    );
  }

  // Invitations
  @override
  Future<Response> getInvitations({int page = 1, int limit = 20}) {
    return dio.get(ApiEndpoints.classInvitations, queryParameters: {'page': page, 'limit': limit});
  }

  @override
  Future<Response> lookupInvites(String classId, List<String> emails) {
    return dio.post(
      '${ApiEndpoints.classInvites}$classId/invitations/lookup',
      data: {'emails': emails},
    );
  }

  @override
  Future<Response> sendInvites(String classId, List<String> emails) {
    return dio.post('${ApiEndpoints.classInvites}$classId/invitations', data: {'emails': emails});
  }

  @override
  Future<Response> revokeInvite(String classId, String userId) {
    return dio.delete('${ApiEndpoints.classInvites}$classId/invitations/$userId');
  }

  @override
  Future<Response> acceptInvite(String classId) {
    return dio.post('${ApiEndpoints.classInvites}$classId/invitations/accept');
  }

  @override
  Future<Response> declineInvite(String classId) {
    return dio.post('${ApiEndpoints.classInvites}$classId/invitations/decline');
  }

  // Materials
  @override
  Future<Response> addMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
    String? duplicatePolicy,
  }) {
    return dio.post(
      '${ApiEndpoints.classMaterials}$classId/materials',
      data: {'deckIds': deckIds, 'folderIds': folderIds, 'duplicatePolicy': ?duplicatePolicy},
    );
  }

  @override
  Future<Response> checkMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  }) {
    return dio.post(
      '${ApiEndpoints.classMaterialsCheck}$classId/materials/check',
      data: {'deckIds': deckIds, 'folderIds': folderIds},
    );
  }

  @override
  Future<Response> deleteMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  }) {
    // Id là id BẢN SAO trong lớp (lấy từ GET /materials). DELETE mang body JSON.
    return dio.delete(
      '${ApiEndpoints.classMaterials}$classId/materials',
      data: {'deckIds': deckIds, 'folderIds': folderIds},
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
  Future<Response> getFolderDecks(
    String classId,
    String folderId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    return dio.get(
      '${ApiEndpoints.classMaterialFolderDecks}$classId/materials/folders/$folderId/decks',
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
    required String targetType,
    required String targetId,
  }) {
    return dio.post(
      '${ApiEndpoints.classClone}$classId/clone',
      data: {'targetType': targetType, 'targetId': targetId},
    );
  }

  // Assignments
  Map<String, dynamic> _assignmentBody({
    required String title,
    String? description,
    DateTime? startAt,
    required DateTime endAt,
    String? mode,
    String? scope,
    int? targetCount,
    List<Map<String, dynamic>>? sources,
    String? testId,
  }) {
    return {
      'title': title,
      'description': ?description,
      // Bỏ trống `startAt` = giao ngay. ISO-8601 CÓ múi giờ (UTC).
      'startAt': startAt?.toUtc().toIso8601String(),
      'endAt': endAt.toUtc().toIso8601String(),
      'mode': ?mode,
      'scope': ?scope,
      'targetCount': ?targetCount,
      'sources': ?sources,
      'testId': ?testId,
    };
  }

  @override
  Future<Response> createAssignment(
    String classId, {
    required String title,
    String? description,
    required String type,
    DateTime? startAt,
    required DateTime endAt,
    String? mode,
    String? scope,
    int? targetCount,
    List<Map<String, dynamic>>? sources,
    String? testId,
  }) {
    return dio.post(
      '${ApiEndpoints.classAssignments}$classId/assignments',
      data: {
        'type': type,
        ..._assignmentBody(
          title: title,
          description: description,
          startAt: startAt,
          endAt: endAt,
          mode: mode,
          scope: scope,
          targetCount: targetCount,
          sources: sources,
          testId: testId,
        ),
      },
    );
  }

  @override
  Future<Response> updateAssignment(
    String classId,
    String assignmentId, {
    required String title,
    String? description,
    DateTime? startAt,
    required DateTime endAt,
    String? mode,
    String? scope,
    int? targetCount,
    List<Map<String, dynamic>>? sources,
    String? testId,
  }) {
    return dio.put(
      '${ApiEndpoints.classes}/$classId/assignments/$assignmentId',
      data: _assignmentBody(
        title: title,
        description: description,
        startAt: startAt,
        endAt: endAt,
        mode: mode,
        scope: scope,
        targetCount: targetCount,
        sources: sources,
        testId: testId,
      ),
    );
  }

  @override
  Future<Response> deleteAssignment(String classId, String assignmentId) {
    return dio.delete('${ApiEndpoints.classes}/$classId/assignments/$assignmentId');
  }

  @override
  Future<Response> getAssignments(
    String classId, {
    String tab = 'active',
    int page = 1,
    int limit = 20,
  }) {
    return dio.get(
      '${ApiEndpoints.classAssignments}$classId/assignments',
      queryParameters: {'tab': tab, 'page': page, 'limit': limit},
    );
  }

  @override
  Future<Response> getSubmissions(
    String classId,
    String assignmentId, {
    int page = 1,
    int limit = 20,
  }) {
    return dio.get(
      '${ApiEndpoints.classAssignmentSubmissions}$classId/assignments/$assignmentId/submissions',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  @override
  Future<Response> getMySubmissions(String classId, {int page = 1, int limit = 20}) {
    return dio.get(
      '${ApiEndpoints.classMySubmissions}$classId/my-submissions',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  @override
  Future<Response> getOverdueAssignments(String classId, {int page = 1, int limit = 20}) {
    return dio.get(
      '${ApiEndpoints.classAssignmentsOverdue}$classId/assignments/overdue',
      queryParameters: {'page': page, 'limit': limit},
    );
  }

  @override
  Future<Response> getLeaderboard(String classId, {String? month, int limit = 10}) {
    return dio.get(
      '${ApiEndpoints.classLeaderboard}$classId/leaderboard',
      // Không gửi `month` = tháng hiện tại (giờ VN) theo BE.
      queryParameters: {'month': ?month, 'limit': limit},
    );
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
  Future<Response> getAssignmentDrillDown(
    String classId,
    String assignmentId, {
    required String status,
  }) {
    return dio.get(
      '${ApiEndpoints.analyticsAssignmentDrillDown}$classId/assignments/$assignmentId/drill-down',
      queryParameters: {'status': status},
    );
  }

  @override
  Future<Response> getScoreDistribution(String classId, String assignmentId) {
    return dio.get(
      '${ApiEndpoints.analyticsScoreDistribution}$classId/assignments/$assignmentId/score-distribution',
    );
  }

  @override
  Future<Response> getStudentAttempts(String classId, String assignmentId, String userId) {
    return dio.get(
      '${ApiEndpoints.analyticsStudentAttempts}$classId/assignments/$assignmentId/students/$userId/attempts',
    );
  }

  @override
  Future<Response> getAttemptDetail(String classId, String attemptId) {
    return dio.get('${ApiEndpoints.analyticsAttemptDetail}$classId/attempts/$attemptId');
  }

  @override
  Future<Response> getStudentAssignments(String classId, String userId) {
    return dio.get(
      '${ApiEndpoints.analyticsStudentAssignments}$classId/students/$userId/assignments',
    );
  }
}

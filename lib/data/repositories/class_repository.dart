import 'package:mind_deck/data/data_sources/remote/class_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/class/class_settings_model.dart';
import 'package:mind_deck/data/models/class/class_invitation_model.dart';
import 'package:mind_deck/data/models/class/class_material_response_model.dart';
import 'package:mind_deck/data/models/class/class_leaderboard_response_model.dart';
import 'package:mind_deck/data/models/class/class_analytics_models.dart';
import 'package:mind_deck/data/models/class/class_assignment_model.dart';
import 'package:mind_deck/data/models/class/class_assignment_submission_model.dart';
import 'package:mind_deck/data/models/test_attempt_detail_model.dart';
import 'package:mind_deck/core/api_handler.dart';

/// Số dòng mỗi trang của các danh sách lớp học (mặc định của BE). BE không trả tổng số hay `hasMore`:
/// danh sách hết khi một trang trả ít hơn số dòng này.
const int classPageSize = 20;

abstract class ClassRepository {
  // Class management
  Future<ApiListResponse<ClassModel>> getClasses({int page = 1, int limit = classPageSize});
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

  /// Chỉ owner. Xóa mềm, xóa cứng sau 90 ngày. `reason` tùy chọn.
  Future<ApiResponse<void>> deleteClass(String classId, {String? reason});

  /// Gửi `joinCode` HOẶC `classId` (lớp công khai).
  Future<ApiResponse<JoinResult>> joinClass({String? joinCode, String? classId});
  Future<ApiResponse<ClassModel>> previewClass(String code);
  Future<ApiResponse<void>> approveMember(String classId, String userId);

  /// Từ chối (pending) / thu hồi lời mời (invited) / đuổi (approved) theo trạng thái hiện tại.
  Future<ApiResponse<RemoveMemberResult>> kickMember(String classId, String userId);
  Future<ApiResponse<void>> updateMemberRole(String classId, String userId, String role);
  Future<ApiListResponse<ClassMemberModel>> getPendingMembers(
    String classId, {
    String status = 'pending',
    int page = 1,
    int limit = classPageSize,
  });
  Future<ApiListResponse<ClassMemberModel>> getMembers(
    String classId, {
    int page = 1,
    int limit = classPageSize,
  });
  Future<ApiResponse<void>> leaveClass(String classId);

  /// Chỉ chủ lớp. 400 `CLASS_NEW_OWNER_INVALID` khi người nhận không hợp lệ.
  Future<ApiResponse<void>> transferOwner(String classId, String userId);

  /// Học viên hủy yêu cầu xin vào lớp đang chờ. 404 `CLASS_REQUEST_NOT_FOUND` nếu không còn yêu cầu.
  Future<ApiResponse<void>> cancelMyJoinRequest(String classId);

  /// Chỉ gửi khóa muốn đổi. `notifications` là map con (khóa snake_case).
  Future<ApiResponse<ClassSettings>> updateClassSettings(
    String classId, {
    bool? allowMemberAdd,
    bool? allowMemberClone,
    bool? showLeaderboard,
    bool? showMemberEmails,
    Map<String, bool>? notifications,
  });
  Future<ApiResponse<MyNotifySettings>> updateMyNotifications(
    String classId, {
    bool? muted,
    Map<String, bool>? types,
  });

  // Invitations
  Future<ApiListResponse<ClassInvitationModel>> getInvitations({
    int page = 1,
    int limit = classPageSize,
  });
  Future<ApiResponse<List<InviteLookupRow>>> lookupInvites(String classId, List<String> emails);
  Future<ApiResponse<List<InviteLookupRow>>> sendInvites(String classId, List<String> emails);
  Future<ApiResponse<void>> revokeInvite(String classId, String userId);
  Future<ApiResponse<JoinResult>> acceptInvite(String classId);
  Future<ApiResponse<void>> declineInvite(String classId);

  // Materials
  /// Ném `ServerFailure` 409 `CLASS_MATERIAL_DUPLICATE` (kèm `params.duplicates`) khi có học liệu
  /// trùng mà chưa gửi `duplicatePolicy` (skip | add_anyway | merge).
  Future<ApiResponse<AddMaterialsResult>> addMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
    String? duplicatePolicy,
  });
  Future<ApiResponse<CheckMaterialsResult>> checkMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  });

  /// Id phải là id BẢN SAO trong lớp (lấy từ [getMaterials]).
  Future<ApiResponse<RemoveMaterialsResult>> deleteMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  });
  Future<ClassMaterialsPage> getMaterials(
    String classId, {
    int page = 1,
    int limit = 20,
    String? search,
  });
  Future<ClassMaterialsPage> getFolderDecks(
    String classId,
    String folderId, {
    int page = 1,
    int limit = 20,
    String? search,
  });

  /// `targetType`: 'deck' | 'folder'; `targetId` là id BẢN SAO trong lớp. Trả deck/folder cá nhân mới.
  Future<ApiResponse<Map<String, dynamic>>> cloneClassMaterials(
    String classId, {
    required String targetType,
    required String targetId,
  });

  // Assignments
  /// Bài học (`study_mission`) cần `mode` + `scope` (+ `targetCount` khi `scope = count`) + `sources`
  /// (id BẢN SAO deck / folder của lớp); bài kiểm tra (`graded_test`) cần `testId`.
  /// `startAt` bỏ trống = giao ngay. Phase của response luôn là `scheduled`: hãy tải lại danh sách.
  Future<ApiResponse<ClassAssignmentModel>> createAssignment(
    String classId, {
    required String title,
    String? description,
    required AssignmentType type,
    DateTime? startAt,
    required DateTime endAt,
    String? mode,
    String? scope,
    int? targetCount,
    List<AssignmentSource>? sources,
    String? testId,
  });

  /// 403 `CLASS_ASSIGNMENT_LOCKED` khi đổi nội dung / giờ bắt đầu mà bài đã có hoạt động.
  Future<ApiResponse<ClassAssignmentModel>> updateAssignment(
    String classId,
    String assignmentId, {
    required String title,
    String? description,
    DateTime? startAt,
    required DateTime endAt,
    String? mode,
    String? scope,
    int? targetCount,
    List<AssignmentSource>? sources,
    String? testId,
  });
  Future<ApiResponse<void>> deleteAssignment(String classId, String assignmentId);
  Future<ApiListResponse<ClassAssignmentModel>> getAssignments(
    String classId, {
    String tab = 'active',
    int page = 1,
    int limit = classPageSize,
  });

  /// Roster của một bài giao: mọi học viên được giao (kể cả chưa làm / bị bỏ qua).
  Future<ApiListResponse<AssignmentDrillDownModel>> getSubmissions(
    String classId,
    String assignmentId, {
    int page = 1,
    int limit = classPageSize,
  });
  Future<ApiListResponse<ClassAssignmentSubmissionModel>> getMySubmissions(
    String classId, {
    int page = 1,
    int limit = classPageSize,
  });
  Future<ApiListResponse<ClassAssignmentSubmissionModel>> getOverdueAssignments(
    String classId, {
    int page = 1,
    int limit = classPageSize,
  });

  /// Bảng xếp hạng theo THÁNG. `month` dạng `YYYY-MM`; null = tháng hiện tại.
  Future<ApiResponse<ClassLeaderboardResponseModel>> getLeaderboard(
    String classId, {
    String? month,
    int limit = 10,
  });

  // Analytics
  /// Giảng viên BẮT BUỘC truyền `studentId` (id của chính mình để xem của mình).
  Future<ApiListResponse<ReviewWorkloadModel>> getReviewWorkload(
    String classId, {
    String? studentId,
    String? timezone,
  });
  Future<ApiListResponse<HardestCardModel>> getHardestCards(String classId, {String? studentId});

  /// BE trả OBJECT (trước đây là mảng). Bỏ `deckId` = toàn bộ deck của lớp.
  Future<ApiResponse<DeckHealthResponse>> getDeckHealth(
    String classId, {
    String? deckId,
    String? studentId,
  });

  /// Luôn đủ 6 trạng thái: scheduled, pending, in_progress, completed, overdue, skipped.
  Future<ApiListResponse<AssignmentProgressModel>> getAssignmentProgress(
    String classId,
    String assignmentId,
  );

  /// `status` bắt buộc (một trong 6 trạng thái ở trên).
  Future<ApiListResponse<AssignmentDrillDownModel>> getAssignmentDrillDown(
    String classId,
    String assignmentId, {
    required String status,
  });
  Future<ApiResponse<ScoreDistribution>> getScoreDistribution(String classId, String assignmentId);
  Future<ApiListResponse<StudentAttemptModel>> getStudentAttempts(
    String classId,
    String assignmentId,
    String userId,
  );
  Future<ApiResponse<TestAttemptDetailModel>> getAttemptDetail(String classId, String attemptId);
  Future<ApiListResponse<StudentAssignmentResult>> getStudentAssignments(
    String classId,
    String userId,
  );
}

class ClassRepositoryImpl with ApiHandler implements ClassRepository {
  final ClassRemoteDataSource remoteDataSource;

  ClassRepositoryImpl({required this.remoteDataSource});

  // Class management
  @override
  Future<ApiListResponse<ClassModel>> getClasses({int page = 1, int limit = classPageSize}) async {
    return executeApi(() async {
      final response = await remoteDataSource.getClasses(page: page, limit: limit);
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
  Future<ApiResponse<void>> deleteClass(String classId, {String? reason}) async {
    return executeApi(() async {
      final response = await remoteDataSource.deleteClass(classId, reason: reason);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<JoinResult>> joinClass({String? joinCode, String? classId}) async {
    return executeApi(() async {
      final response = await remoteDataSource.joinClass(joinCode: joinCode, classId: classId);
      return ApiResponse<JoinResult>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => JoinResult.fromJson(json),
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
  Future<ApiResponse<RemoveMemberResult>> kickMember(String classId, String userId) async {
    return executeApi(() async {
      final response = await remoteDataSource.kickMember(classId, userId);
      return ApiResponse<RemoveMemberResult>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RemoveMemberResult.fromJson(json),
      );
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
  Future<ApiListResponse<ClassMemberModel>> getPendingMembers(
    String classId, {
    String status = 'pending',
    int page = 1,
    int limit = classPageSize,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getPendingMembers(
        classId,
        status: status,
        page: page,
        limit: limit,
      );
      return ApiListResponse<ClassMemberModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassMemberModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<ClassMemberModel>> getMembers(
    String classId, {
    int page = 1,
    int limit = classPageSize,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getMembers(classId, page: page, limit: limit);
      return ApiListResponse<ClassMemberModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassMemberModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> leaveClass(String classId) async {
    return executeApi(() async {
      final response = await remoteDataSource.leaveClass(classId);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> transferOwner(String classId, String userId) async {
    return executeApi(() async {
      final response = await remoteDataSource.transferOwner(classId, userId);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<void>> cancelMyJoinRequest(String classId) async {
    return executeApi(() async {
      final response = await remoteDataSource.cancelMyJoinRequest(classId);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<ClassSettings>> updateClassSettings(
    String classId, {
    bool? allowMemberAdd,
    bool? allowMemberClone,
    bool? showLeaderboard,
    bool? showMemberEmails,
    Map<String, bool>? notifications,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.patchClassSettings(classId, {
        'allowMemberAdd': ?allowMemberAdd,
        'allowMemberClone': ?allowMemberClone,
        'showLeaderboard': ?showLeaderboard,
        'showMemberEmails': ?showMemberEmails,
        'notifications': ?notifications,
      });
      return ApiResponse<ClassSettings>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassSettings.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<MyNotifySettings>> updateMyNotifications(
    String classId, {
    bool? muted,
    Map<String, bool>? types,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.patchMyNotifications(classId, {
        'muted': ?muted,
        ...?types,
      });
      return ApiResponse<MyNotifySettings>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MyNotifySettings.fromJson(json),
      );
    });
  }

  // Invitations
  @override
  Future<ApiListResponse<ClassInvitationModel>> getInvitations({
    int page = 1,
    int limit = classPageSize,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getInvitations(page: page, limit: limit);
      return ApiListResponse<ClassInvitationModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassInvitationModel.fromJson(json),
      );
    });
  }

  List<InviteLookupRow> _parseInviteRows(dynamic data) => data is List
      ? [
          for (final e in data)
            if (e is Map<String, dynamic>) InviteLookupRow.fromJson(e),
        ]
      : const [];

  @override
  Future<ApiResponse<List<InviteLookupRow>>> lookupInvites(
    String classId,
    List<String> emails,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.lookupInvites(classId, emails);
      return ApiResponse<List<InviteLookupRow>>.fromJsonAny(
        response.data as Map<String, dynamic>,
        _parseInviteRows,
      );
    });
  }

  @override
  Future<ApiResponse<List<InviteLookupRow>>> sendInvites(
    String classId,
    List<String> emails,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.sendInvites(classId, emails);
      return ApiResponse<List<InviteLookupRow>>.fromJsonAny(
        response.data as Map<String, dynamic>,
        _parseInviteRows,
      );
    });
  }

  @override
  Future<ApiResponse<void>> revokeInvite(String classId, String userId) async {
    return executeApi(() async {
      final response = await remoteDataSource.revokeInvite(classId, userId);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  @override
  Future<ApiResponse<JoinResult>> acceptInvite(String classId) async {
    return executeApi(() async {
      final response = await remoteDataSource.acceptInvite(classId);
      return ApiResponse<JoinResult>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => JoinResult.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<void>> declineInvite(String classId) async {
    return executeApi(() async {
      final response = await remoteDataSource.declineInvite(classId);
      return ApiResponse<void>.fromJson(response.data as Map<String, dynamic>, (_) => {});
    });
  }

  // Materials
  @override
  Future<ApiResponse<AddMaterialsResult>> addMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
    String? duplicatePolicy,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.addMaterials(
        classId,
        folderIds: folderIds,
        deckIds: deckIds,
        duplicatePolicy: duplicatePolicy,
      );
      return ApiResponse<AddMaterialsResult>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AddMaterialsResult.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<CheckMaterialsResult>> checkMaterials(
    String classId, {
    required List<String> folderIds,
    required List<String> deckIds,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.checkMaterials(
        classId,
        folderIds: folderIds,
        deckIds: deckIds,
      );
      return ApiResponse<CheckMaterialsResult>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CheckMaterialsResult.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<RemoveMaterialsResult>> deleteMaterials(
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
      return ApiResponse<RemoveMaterialsResult>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => RemoveMaterialsResult.fromJson(json),
      );
    });
  }

  @override
  Future<ClassMaterialsPage> getMaterials(
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
      return ClassMaterialsPage.fromBody(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<ClassMaterialsPage> getFolderDecks(
    String classId,
    String folderId, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getFolderDecks(
        classId,
        folderId,
        page: page,
        limit: limit,
        search: search,
      );
      return ClassMaterialsPage.fromBody(
        response.data as Map<String, dynamic>,
        itemFallbackType: ClassMaterialItem.typeDeck,
      );
    });
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> cloneClassMaterials(
    String classId, {
    required String targetType,
    required String targetId,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.cloneClassMaterials(
        classId,
        targetType: targetType,
        targetId: targetId,
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );
    });
  }

  // Assignments
  @override
  Future<ApiResponse<ClassAssignmentModel>> createAssignment(
    String classId, {
    required String title,
    String? description,
    required AssignmentType type,
    DateTime? startAt,
    required DateTime endAt,
    String? mode,
    String? scope,
    int? targetCount,
    List<AssignmentSource>? sources,
    String? testId,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.createAssignment(
        classId,
        title: title,
        description: description,
        type: type.toJson(),
        startAt: startAt,
        endAt: endAt,
        mode: mode,
        scope: scope,
        targetCount: targetCount,
        sources: sources?.map((s) => s.toJson()).toList(),
        testId: testId,
      );
      return ApiResponse<ClassAssignmentModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassAssignmentModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<ClassAssignmentModel>> updateAssignment(
    String classId,
    String assignmentId, {
    required String title,
    String? description,
    DateTime? startAt,
    required DateTime endAt,
    String? mode,
    String? scope,
    int? targetCount,
    List<AssignmentSource>? sources,
    String? testId,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.updateAssignment(
        classId,
        assignmentId,
        title: title,
        description: description,
        startAt: startAt,
        endAt: endAt,
        mode: mode,
        scope: scope,
        targetCount: targetCount,
        sources: sources?.map((s) => s.toJson()).toList(),
        testId: testId,
      );
      return ApiResponse<ClassAssignmentModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassAssignmentModel.fromJson(json),
      );
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
    int page = 1,
    int limit = classPageSize,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getAssignments(
        classId,
        tab: tab,
        page: page,
        limit: limit,
      );
      return ApiListResponse<ClassAssignmentModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassAssignmentModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<AssignmentDrillDownModel>> getSubmissions(
    String classId,
    String assignmentId, {
    int page = 1,
    int limit = classPageSize,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getSubmissions(
        classId,
        assignmentId,
        page: page,
        limit: limit,
      );
      return ApiListResponse<AssignmentDrillDownModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => AssignmentDrillDownModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<ClassAssignmentSubmissionModel>> getMySubmissions(
    String classId, {
    int page = 1,
    int limit = classPageSize,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getMySubmissions(classId, page: page, limit: limit);
      return ApiListResponse<ClassAssignmentSubmissionModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassAssignmentSubmissionModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<ClassAssignmentSubmissionModel>> getOverdueAssignments(
    String classId, {
    int page = 1,
    int limit = classPageSize,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getOverdueAssignments(
        classId,
        page: page,
        limit: limit,
      );
      return ApiListResponse<ClassAssignmentSubmissionModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ClassAssignmentSubmissionModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<ClassLeaderboardResponseModel>> getLeaderboard(
    String classId, {
    String? month,
    int limit = 10,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.getLeaderboard(classId, month: month, limit: limit);
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
  Future<ApiResponse<DeckHealthResponse>> getDeckHealth(
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
      return ApiResponse<DeckHealthResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => DeckHealthResponse.fromJson(json),
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
    required String status,
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

  @override
  Future<ApiResponse<ScoreDistribution>> getScoreDistribution(
    String classId,
    String assignmentId,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.getScoreDistribution(classId, assignmentId);
      return ApiResponse<ScoreDistribution>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => ScoreDistribution.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<StudentAttemptModel>> getStudentAttempts(
    String classId,
    String assignmentId,
    String userId,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.getStudentAttempts(classId, assignmentId, userId);
      return ApiListResponse<StudentAttemptModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => StudentAttemptModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiResponse<TestAttemptDetailModel>> getAttemptDetail(
    String classId,
    String attemptId,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.getAttemptDetail(classId, attemptId);
      return ApiResponse<TestAttemptDetailModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => TestAttemptDetailModel.fromJson(json),
      );
    });
  }

  @override
  Future<ApiListResponse<StudentAssignmentResult>> getStudentAssignments(
    String classId,
    String userId,
  ) async {
    return executeApi(() async {
      final response = await remoteDataSource.getStudentAssignments(classId, userId);
      return ApiListResponse<StudentAssignmentResult>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => StudentAssignmentResult.fromJson(json),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/core/failures.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/study/study_session_model.dart';
import 'package:mind_deck/data/repositories/study_repository.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';

class StudyFlowHelper {
  static String _errorMessage(Object e) {
    if (e is Failure) {
      switch (e.errorCode) {
        case 'DECK_NOT_FOUND':
          return 'Bộ thẻ không tồn tại hoặc bạn không còn quyền học bộ thẻ này';
        case 'STUDY_NO_CARDS_FOUND':
          return 'Không có thẻ nào bạn có thể học trong lựa chọn này';
        case 'STUDY_NO_ACTIVE_SESSION':
          return 'Phiên học này không còn nữa, hãy bắt đầu phiên mới';
      }
      if (e.message.isNotEmpty) return e.message;
    }
    return 'Có lỗi xảy ra, vui lòng thử lại sau';
  }

  static Future<void> start({
    required BuildContext context,
    String? deckId,
    List<String>? cardIds,
    int? timeLimitSeconds,
    String? questionSide,
    String? sessionId,
    bool replace = false,

    /// Chỉ với `deckId`: bỏ tiến độ cũ của bộ thẻ và học lại từ đầu (không thì BE tiếp tục phiên dở).
    bool restart = false,
  }) async {
    final studyRepo = DI().sl<StudyRepository>();
    try {
      final ApiResponse<StudySessionModel> response;
      if (sessionId != null && sessionId.isNotEmpty) {
        response = await studyRepo.resumeStudySession(sessionId);
      } else if (deckId != null && deckId.isNotEmpty) {
        response = await studyRepo.startStudySession(
          deckId: deckId,
          timeLimitSeconds: timeLimitSeconds,
          restart: restart,
        );
      } else {
        response = await studyRepo.startStudySession(
          cardIds: cardIds,
          timeLimitSeconds: timeLimitSeconds,
        );
      }
      // 2. Nếu lỗi hoặc không có thẻ: Báo lỗi ngay tại màn hình hiện tại
      final session = response.data;
      // Học thử (readOnly) không có sessionId; phiên thường bắt buộc phải có.
      if (!response.success ||
          session == null ||
          session.cards.isEmpty ||
          (!session.readOnly && session.sessionId.isEmpty)) {
        if (context.mounted) {
          CustomToast.show(
            context,
            CustomToast.danger(
              message: response.message ?? 'Không thể bắt đầu phiên học, vui lòng thử lại sau',
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        final sessionTimeLimit = response.data!.timeLimitSeconds > 0
            ? response.data!.timeLimitSeconds
            : (timeLimitSeconds ?? 0);
        final showBackFirst = questionSide == 'back';

        final extra = {
          "sessionId": response.data!.sessionId,
          "cards": response.data!.cards.map((c) => c.toJson()).toList(),
          "reviewLogs": response.data!.reviewLogs,
          "timeLimitSeconds": sessionTimeLimit,
          "elapsedSeconds": response.data!.elapsedSeconds,
          "readOnly": response.data!.readOnly,
          "showBackFirst": showBackFirst,
          // Phiên bắt đầu theo bộ thẻ thì "Học lại" phải gửi `restart: true` cho đúng bộ thẻ đó;
          // phiên nhiều nguồn (hoặc tiếp tục bằng sessionId) thì học lại đúng nhóm thẻ đã học.
          "restartDeckId": (sessionId == null || sessionId.isEmpty) ? deckId : null,
        };
        if (replace) {
          context.pushReplacementNamed(AppRoute.flashcardStudy.name, extra: extra);
        } else {
          context.pushNamed(AppRoute.flashcardStudy.name, extra: extra);
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomToast.show(context, CustomToast.danger(message: _errorMessage(e)));
      }
    }
  }
}

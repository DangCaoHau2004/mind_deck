import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/study/study_session_model.dart';
import 'package:mind_deck/data/repositories/study_repository.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';

class StudyFlowHelper {
  static Future<void> start({
    required BuildContext context,
    String? deckId,
    List<String>? cardIds,
    String? sessionId,
    bool replace = false,
  }) async {
    final studyRepo = DI().sl<StudyRepository>();
    try {
      final ApiResponse<StudySessionModel> response;
      if (sessionId != null && sessionId.isNotEmpty) {
        response = await studyRepo.resumeStudySession(sessionId);
      } else if (deckId != null && deckId.isNotEmpty) {
        response = await studyRepo.startStudySession(deckId: deckId);
      } else {
        response = await studyRepo.startStudySession(cardIds: cardIds);
      }
      // 2. Nếu lỗi hoặc không có thẻ: Báo lỗi ngay tại màn hình hiện tại
      if (!response.success ||
          response.data == null ||
          response.data!.cards.isEmpty ||
          response.data!.sessionId.isEmpty) {
        if (context.mounted) {
          CustomToast.show(
            context,
            CustomToast.danger(message: 'Không thể bắt đầu phiên học, vui lòng thử lại sau'),
          );
        }
        return;
      }
      if (context.mounted) {
        final extra = {
          "sessionId": response.data!.sessionId,
          "cards": response.data!.cards.map((c) => c.toJson()).toList(),
          "reviewLogs": response.data!.reviewLogs,
        };
        if (replace) {
          context.pushReplacementNamed(AppRoute.flashcardStudy.name, extra: extra);
        } else {
          context.pushNamed(AppRoute.flashcardStudy.name, extra: extra);
        }
      }
    } catch (_) {
      if (context.mounted) {
        CustomToast.show(
          context,
          CustomToast.danger(message: 'Có lỗi xảy ra, vui lòng thử lại sau'),
        );
      }
    }
  }
}

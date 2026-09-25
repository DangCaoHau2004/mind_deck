import 'package:mind_deck/data/data_sources/remote/review_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/user_card_progress_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class ReviewRepository {
  Future<ApiResponse<UserCardProgressModel>> submitReview({
    required String cardId,
    required int grade,
    String? reviewTimestamp,
    int? durationMs,
  });
}

class ReviewRepositoryImpl with ApiHandler implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;

  ReviewRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<UserCardProgressModel>> submitReview({
    required String cardId,
    required int grade,
    String? reviewTimestamp,
    int? durationMs,
  }) async {
    return executeApi(() async {
      final response = await remoteDataSource.submitReview(
        cardId: cardId,
        grade: grade,
        reviewTimestamp: reviewTimestamp,
        durationMs: durationMs,
      );
      return ApiResponse<UserCardProgressModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserCardProgressModel.fromJson(json),
      );
    });
  }
}

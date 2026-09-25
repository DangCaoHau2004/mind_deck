import 'package:dio/dio.dart';
import 'package:mind_deck/constants/api_endpoints.dart';

abstract class ReviewRemoteDataSource {
  Future<Response> submitReview({
    required String cardId,
    required int grade,
    String? reviewTimestamp,
    int? durationMs,
  });
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final Dio dio;

  ReviewRemoteDataSourceImpl({required this.dio});

  @override
  Future<Response> submitReview({
    required String cardId,
    required int grade,
    String? reviewTimestamp,
    int? durationMs,
  }) {
    return dio.post(
      ApiEndpoints.review,
      data: {
        'cardId': cardId,
        'grade': grade,
        'reviewTimestamp': ?reviewTimestamp,
        'durationMs': ?durationMs,
      },
    );
  }
}

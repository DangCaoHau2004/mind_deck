import 'package:mind_deck/core/api_handler.dart';
import 'package:mind_deck/data/data_sources/remote/coin_remote_data_source.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/data/models/coin_models.dart';

abstract class CoinRepository {
  Future<CoinInfo> getCoins();
  Future<CoinHistoryPage> getHistory({int page = 1, int limit = 20});
}

class CoinRepositoryImpl with ApiHandler implements CoinRepository {
  final CoinRemoteDataSource remoteDataSource;

  CoinRepositoryImpl({required this.remoteDataSource});

  @override
  Future<CoinInfo> getCoins() {
    return executeApi(() async {
      final response = await remoteDataSource.getCoins();
      final data = (response.data as Map<String, dynamic>)['data'];
      return CoinInfo.fromJson(data is Map<String, dynamic> ? data : const {});
    });
  }

  @override
  Future<CoinHistoryPage> getHistory({int page = 1, int limit = 20}) {
    return executeApi(() async {
      final response = await remoteDataSource.getHistory(page: page, limit: limit);
      final list = ApiListResponse<CoinTransaction>.fromJson(
        response.data as Map<String, dynamic>,
        CoinTransaction.fromJson,
      );
      // BE không trả hasMore thì suy từ số dòng của trang.
      return CoinHistoryPage(items: list.data, hasMore: list.hasMore ?? list.data.length >= limit);
    });
  }
}

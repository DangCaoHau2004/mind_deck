import 'package:mind_deck/data/data_sources/remote/profile_remote_data_source.dart';
import 'package:mind_deck/data/models/user_model.dart';
import 'package:mind_deck/data/models/api_response_model.dart';
import 'package:mind_deck/core/api_handler.dart';

abstract class ProfileRepository {
  Future<ApiResponse<UserModel>> getProfile();
  Future<UserModel> updateProfile({required Map<String, dynamic> data});
  Future<void> linkGoogle({required String token});
  Future<void> unlinkGoogle();
}

class ProfileRepositoryImpl with ApiHandler implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<UserModel>> getProfile() async {
    return executeApi(() async {
      final response = await remoteDataSource.getProfile();
      return ApiResponse<UserModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          return UserModel.fromJson(json);
        },
      );
    });
  }

  @override
  Future<UserModel> updateProfile({required Map<String, dynamic> data}) async {
    final response = await executeApi(
      () => remoteDataSource.updateProfile(data: data),
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> linkGoogle({required String token}) async {
    await executeApi(() => remoteDataSource.linkGoogle(token: token));
  }

  @override
  Future<void> unlinkGoogle() async {
    await executeApi(() => remoteDataSource.unlinkGoogle());
  }
}

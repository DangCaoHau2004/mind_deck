import 'package:google_sign_in/google_sign_in.dart';
import 'package:mind_deck/core/failures.dart';

abstract class GoogleAuthRemoteDataSource {
  Future<String?> getGoogleToken();
}

class GoogleAuthRemoteDataSourceImpl implements GoogleAuthRemoteDataSource {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;
  @override
  Future<String?> getGoogleToken() async {
    try {
      if (!_isInitialized) {
        // Không truyền serverClientId: plugin Android tự lấy mã web trong google-services.json của flavor.
        await _googleSignIn.initialize();
        _isInitialized = true;
      }
      await _googleSignIn.signOut();
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;
      return auth.idToken;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('canceled') ||
          errorStr.contains('cancelled') ||
          errorStr.contains('sign_in_canceled') ||
          errorStr.contains('sign_in_cancelled')) {
        return null;
      }
      throw UnknownFailure(message: 'Lỗi lấy token Google: $e');
    }
  }
}

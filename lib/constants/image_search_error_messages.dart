import 'package:mind_deck/constants/app_error_codes.dart';
import 'package:mind_deck/core/extensions/string_extension.dart';
import 'package:mind_deck/core/failures.dart';

class ImageSearchErrorMessages {
  ImageSearchErrorMessages._();

  static String of(Failure failure) {
    switch (failure.errorCode) {
      case AppErrorCodes.imageSearchTooManyRequests:
      case AppErrorCodes.imageSearchRateLimited:
        return 'image_search_error_too_fast'.tr;
      case AppErrorCodes.imageSearchUnavailable:
      case AppErrorCodes.imageSearchNotConfigured:
        return 'image_search_error_unavailable'.tr;
      case AppErrorCodes.imageSearchQueryTooLong:
        return 'image_search_error_query_too_long'.tr;
      default:
        return failure.message;
    }
  }
}

import 'package:mind_deck/core/services/localization_service.dart';

extension StringExtension on String {
  String get tr {
    return LocalizationService().getString(this);
  }

  String get capitalizeFirst {
    if (trim().isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }

  String get capitalizeWords {
    if (trim().isEmpty) return this;
    return split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}";
        })
        .join(' ');
  }
}

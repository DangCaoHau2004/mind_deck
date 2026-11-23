import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/enums.dart';

extension CardStateExtension on CardState {
  String get label {
    switch (this) {
      case CardState.newCard:
        return 'Chưa học';
      case CardState.learning:
        return 'Đang học';
      case CardState.review:
        return 'Đến hạn';
      case CardState.relearning:
        return 'Học lại';
      case CardState.mastered:
        return 'Thành thạo';
    }
  }

  Color get color {
    switch (this) {
      case CardState.newCard:
        return const Color(0xFFC9D1DD);
      case CardState.learning:
        return const Color(0xFF1565C0);
      case CardState.review:
        return const Color(0xFFEF6C00);
      case CardState.relearning:
        return const Color(0xFFC62828);
      case CardState.mastered:
        return const Color(0xFF2E7D32);
    }
  }
}

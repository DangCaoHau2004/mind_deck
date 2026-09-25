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
        return Colors.grey.shade400;
      case CardState.learning:
        return const Color(0xFFF57C00);
      case CardState.review:
        return const Color(0xFFD32F2F);
      case CardState.relearning:
        return const Color(0xFFC2185B);
      case CardState.mastered:
        return const Color(0xFF388E3C);
    }
  }
}

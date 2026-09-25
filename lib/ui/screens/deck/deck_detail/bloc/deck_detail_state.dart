import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/deck_model.dart';

enum DeckDetailStatus { initial, loading, success, failure, deleted }

class DeckDetailState extends Equatable {
  final DeckDetailStatus status;
  final bool isRefreshing;
  final DeckModel? deck;
  final String? errorMessage;
  final String? successMessage;
  final DateTime? toastTriggerTime;
  final String? clonedDeckId;

  const DeckDetailState({
    this.status = DeckDetailStatus.initial,
    this.isRefreshing = false,
    this.deck,
    this.errorMessage,
    this.successMessage,
    this.toastTriggerTime,
    this.clonedDeckId,
  });

  DeckDetailState copyWith({
    DeckDetailStatus? status,
    bool? isRefreshing,
    DeckModel? deck,
    String? errorMessage,
    String? successMessage,
    DateTime? toastTriggerTime,
    String? clonedDeckId,
  }) {
    return DeckDetailState(
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      deck: deck ?? this.deck,
      errorMessage: errorMessage,
      successMessage: successMessage,
      toastTriggerTime: toastTriggerTime,
      clonedDeckId: clonedDeckId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isRefreshing,
    deck,
    errorMessage,
    successMessage,
    toastTriggerTime,
    clonedDeckId,
  ];
}

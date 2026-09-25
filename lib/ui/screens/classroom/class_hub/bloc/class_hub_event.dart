import 'package:equatable/equatable.dart';

abstract class ClassHubEvent extends Equatable {
  const ClassHubEvent();

  @override
  List<Object?> get props => [];
}

class ClassHubLoaded extends ClassHubEvent {}

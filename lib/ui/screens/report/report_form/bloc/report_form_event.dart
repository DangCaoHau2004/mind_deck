import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:mind_deck/data/models/report_model.dart';

abstract class ReportFormEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReportFormSubmitted extends ReportFormEvent {
  final ReportType type;
  final ReportTargetType targetType;
  final String? targetId;
  final String description;
  final List<File> images;

  ReportFormSubmitted({
    required this.type,
    required this.targetType,
    this.targetId,
    required this.description,
    required this.images,
  });

  @override
  List<Object?> get props => [type, targetType, targetId, description, images];
}

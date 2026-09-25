class ReviewWorkloadModel {
  final DateTime day;
  final int count;

  ReviewWorkloadModel({required this.day, required this.count});

  factory ReviewWorkloadModel.fromJson(Map<String, dynamic> json) {
    return ReviewWorkloadModel(
      day: DateTime.parse(json['day']),
      count: json['count'] as int? ?? 0,
    );
  }
}

class HardestCardModel {
  final String cardId;
  final String frontText;
  final int wrongCount;

  HardestCardModel({
    required this.cardId,
    required this.frontText,
    required this.wrongCount,
  });

  factory HardestCardModel.fromJson(Map<String, dynamic> json) {
    return HardestCardModel(
      cardId: json['cardId'] ?? '',
      frontText: json['frontText'] ?? '',
      wrongCount: json['wrongCount'] as int? ?? 0,
    );
  }
}

class AssignmentProgressModel {
  final String status;
  final int count;

  AssignmentProgressModel({required this.status, required this.count});

  factory AssignmentProgressModel.fromJson(Map<String, dynamic> json) {
    return AssignmentProgressModel(
      status: json['status'] ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class AssignmentDrillDownModel {
  final String userId;
  final String fullName;
  final String email;
  final String status;
  final int progressCount;
  final double? scorePercentage;
  final DateTime? completedAt;

  AssignmentDrillDownModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.status,
    required this.progressCount,
    this.scorePercentage,
    this.completedAt,
  });

  factory AssignmentDrillDownModel.fromJson(Map<String, dynamic> json) {
    return AssignmentDrillDownModel(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? '',
      progressCount: json['progressCount'] as int? ?? 0,
      scorePercentage: json['scorePercentage']?.toDouble(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

class DeckHealthModel {
  final String state;
  final int count;

  DeckHealthModel({required this.state, required this.count});

  factory DeckHealthModel.fromJson(Map<String, dynamic> json) {
    return DeckHealthModel(
      state: json['state'] ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

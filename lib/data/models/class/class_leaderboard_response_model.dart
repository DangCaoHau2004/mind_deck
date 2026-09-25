class LeaderboardEntryModel {
  final String userId;
  final String fullName;
  final int totalScore;
  final int cardsMasteredCount;

  LeaderboardEntryModel({
    required this.userId,
    required this.fullName,
    required this.totalScore,
    required this.cardsMasteredCount,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Người dùng',
      totalScore: json['totalScore'] as int? ?? 0,
      cardsMasteredCount: json['cardsMasteredCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'totalScore': totalScore,
      'cardsMasteredCount': cardsMasteredCount,
    };
  }
}

class ClassLeaderboardResponseModel {
  final List<LeaderboardEntryModel> top10;
  final String? currentUserRank;

  ClassLeaderboardResponseModel({required this.top10, this.currentUserRank});

  factory ClassLeaderboardResponseModel.fromJson(Map<String, dynamic> json) {
    return ClassLeaderboardResponseModel(
      top10:
          (json['top10'] as List?)
              ?.map(
                (e) =>
                    LeaderboardEntryModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      currentUserRank: json['currentUserRank']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'top10': top10.map((e) => e.toJson()).toList(),
      'currentUserRank': currentUserRank,
    };
  }
}

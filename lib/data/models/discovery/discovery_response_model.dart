import 'package:mind_deck/data/models/tag_model.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/discovery/discovery_suggested_content_model.dart';
import 'package:mind_deck/data/models/discovery/discovery_suggested_class_model.dart';

class DiscoveryResponseModel {
  final List<String> trendingKeywords;
  final List<TagModel> popularTopics;
  final List<DiscoverySuggestedContentModel> suggestedContents;
  final List<DiscoverySuggestedClassModel> suggestedClasses;
  final List<DeckModel> personalizedDecks;

  DiscoveryResponseModel({
    required this.trendingKeywords,
    required this.popularTopics,
    required this.suggestedContents,
    required this.suggestedClasses,
    required this.personalizedDecks,
  });

  factory DiscoveryResponseModel.fromJson(Map<String, dynamic> json) {
    return DiscoveryResponseModel(
      trendingKeywords:
          (json['trending_keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['trendingKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      popularTopics:
          (json['popular_topics'] as List<dynamic>?)
              ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['popularTopics'] as List<dynamic>?)
              ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suggestedContents:
          (json['suggested_contents'] as List<dynamic>?)
              ?.map(
                (e) => DiscoverySuggestedContentModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          (json['suggestedContents'] as List<dynamic>?)
              ?.map(
                (e) => DiscoverySuggestedContentModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      suggestedClasses:
          (json['suggested_classes'] as List<dynamic>?)
              ?.map(
                (e) => DiscoverySuggestedClassModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          (json['suggestedClasses'] as List<dynamic>?)
              ?.map(
                (e) => DiscoverySuggestedClassModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      personalizedDecks:
          (json['personalized_decks'] as List<dynamic>?)?.map((e) {
            final data = e as Map<String, dynamic>;
            // Map ownerName to authorName for DeckModel
            if (data.containsKey('ownerName') &&
                !data.containsKey('authorName')) {
              data['authorName'] = data['ownerName'];
            }
            if (data.containsKey('owner_name') &&
                !data.containsKey('author_name')) {
              data['author_name'] = data['owner_name'];
            }
            return DeckModel.fromJson(data);
          }).toList() ??
          (json['personalizedDecks'] as List<dynamic>?)?.map((e) {
            final data = e as Map<String, dynamic>;
            if (data.containsKey('ownerName') &&
                !data.containsKey('authorName')) {
              data['authorName'] = data['ownerName'];
            }
            return DeckModel.fromJson(data);
          }).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trendingKeywords': trendingKeywords,
      'popularTopics': popularTopics.map((e) => e.toJson()).toList(),
      'suggestedContents': suggestedContents.map((e) => e.toJson()).toList(),
      'suggestedClasses': suggestedClasses.map((e) => e.toJson()).toList(),
      'personalizedDecks': personalizedDecks.map((e) => e.toJson()).toList(),
    };
  }
}

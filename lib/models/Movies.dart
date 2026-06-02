import 'package:cloud_firestore/cloud_firestore.dart';

class Movie {
  final String id;

  final Map<String, String>? title;
  final Map<String, String>? description;
  final Map<String, String>? duration;
  final Map<String, String>? releaseYear;
  final Map<String, String>? category;
  final Map<String, String>? cbfc;
  final Map<String, String>? director;
  final Map<String, String>? starcast;

  final String? videoUrl;
  final String? videoUrl2;
  final String? thumbnailUrl;
  final String? creatorId;
  final Timestamp? createdAt;
  final Timestamp? releaseDate;
  final int? views;

  final bool active;

  Movie({
    required this.id,
    this.title,
    this.description,
    this.duration,
    this.releaseYear,
    this.category,
    this.cbfc,
    this.director,
    this.starcast,
    this.videoUrl,
    this.videoUrl2,
    this.thumbnailUrl,
    this.creatorId,
    this.createdAt,
    this.releaseDate,
    this.views,
    required this.active,
    required String titleText,
    required String categoryText,
    required String directorText,
    required String yearText,
    required String durationText,
    required int viewsCount,
  });

  /// ✅ SAFE UI GETTERS (use English by default)
  String get titleText => title?['en'] ?? '';
  String get categoryText => category?['en'] ?? '';
  String get directorText => director?['en'] ?? '';
  String get durationText => duration?['en'] ?? '';
  String get yearText => releaseYear?['en'] ?? '';
  int get viewsCount => views ?? 0;

  // factory Movie.fromFirestore(String id, Map<String, dynamic> data) {
  //   return Movie(
  //     id: id,
  //     title: data['title'] != null
  //         ? Map<String, String>.from(data['title'])
  //         : null,
  //     description: data['description'] != null
  //         ? Map<String, String>.from(data['description'])
  //         : null,
  //     duration: data['duration'] != null
  //         ? Map<String, String>.from(data['duration'])
  //         : null,
  //     releaseYear: data['releaseYear'] != null
  //         ? Map<String, String>.from(data['releaseYear'])
  //         : null,
  //     category: data['category'] != null
  //         ? Map<String, String>.from(data['category'])
  //         : null,
  //     cbfc:
  //         data['cbfc'] != null ? Map<String, String>.from(data['cbfc']) : null,
  //     director: data['director'] != null
  //         ? Map<String, String>.from(data['director'])
  //         : null,
  //     starcast: data['starcast'] != null
  //         ? Map<String, String>.from(data['starcast'])
  //         : null,
  //     videoUrl: data['videoUrl'],
  //     videoUrl2: data['videoUrl2'],
  //     thumbnailUrl: data['thumbnailUrl'],
  //     creatorId: data['creatorId'],
  //     createdAt: data['createdAt'],
  //     releaseDate: data['releaseDate'],
  //     views: data['views'],
  //     active: data['active'] ?? true,
  //     titleText: '',
  //     categoryText: '',
  //     directorText: '',
  //     yearText: '',
  //     durationText: '',
  //     viewsCount: 0,
  //   );
  // }

  factory Movie.fromFirestore(String id, Map<String, dynamic> data) {
    return Movie(
      id: id,
      title: data['title'] != null
          ? Map<String, String>.from(data['title'])
          : null,
      description: data['description'] != null
          ? Map<String, String>.from(data['description'])
          : null,
      duration: data['duration'] != null
          ? Map<String, String>.from(data['duration'])
          : null,
      releaseYear: data['releaseYear'] != null
          ? Map<String, String>.from(data['releaseYear'])
          : null,
      category: data['category'] != null
          ? Map<String, String>.from(data['category'])
          : null,
      cbfc:
          data['cbfc'] != null ? Map<String, String>.from(data['cbfc']) : null,
      director: data['director'] != null
          ? Map<String, String>.from(data['director'])
          : null,
      starcast: data['starcast'] != null
          ? Map<String, String>.from(data['starcast'])
          : null,
      videoUrl: data['videoUrl'],
      videoUrl2: data['videoUrl2'],
      thumbnailUrl: data['thumbnailUrl'],
      creatorId: data['creatorId'],
      createdAt: data['createdAt'] is Timestamp        // 👈 fixed
          ? data['createdAt']
          : data['createdAt'] is String
              ? Timestamp.fromDate(DateTime.parse(data['createdAt']))
              : null,
      releaseDate: data['releaseDate'],
      views: data['views'],
      active: data['active'] ?? true,
      titleText: '',
      categoryText: '',
      directorText: '',
      yearText: '',
      durationText: '',
      viewsCount: 0,
    );
  }
}

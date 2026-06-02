import 'package:cloud_firestore/cloud_firestore.dart';

class VideoData {
  final String id; // Firestore document ID
  final String category;
  final String description;
  final String thumbnailUrl;
  final String title;
  final String videoUrl;
  final DateTime createdAt; // Firestore timestamp

  VideoData({
    required this.id,
    required this.category,
    required this.description,
    required this.thumbnailUrl,
    required this.title,
    required this.videoUrl,
    required this.createdAt, // Include createdAt in the constructor
  });

  /// Factory method to create `VideoData` from Firestore document
  factory VideoData.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    // Check if 'createdAt' exists and is not null before converting to DateTime
    Timestamp? timestamp = data['createdAt'];
    DateTime createdAt = timestamp != null ? timestamp.toDate() : DateTime.now(); // Use current time if null

    return VideoData(
      id: doc.id,
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      title: data['title'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      createdAt: createdAt, // Use the checked value
    );
  }
}

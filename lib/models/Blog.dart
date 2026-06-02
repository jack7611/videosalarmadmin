import 'package:cloud_firestore/cloud_firestore.dart';

class BlogData {
  final String id;
  final String title;
  final String author;
  final String content;
  final String description;
  final String publishedAt; // Storing as String
  final Map<String, String> source; // Map with 'id' and 'name' as Strings
  final String url;
  final String urlToImage;

  BlogData({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
    required this.description,
    required this.publishedAt, // String type
    required this.source, // Map type
    required this.url,
    required this.urlToImage,
  });

  // Convert Firestore document into BlogData
  factory BlogData.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    // Ensure source is a valid map
    final sourceData = data['source'] as Map<String, dynamic>;
    final source = {
      'id': sourceData['id'] as String,
      'name': sourceData['name'] as String,
    };

    return BlogData(
      id: doc.id,
      title: data['title'] as String,
      author: data['author'] as String,
      content: data['content'] as String,
      description: data['description'] as String,
      publishedAt: data['publishedAt'] as String, // Store 'publishedAt' as String
      source: source, // Map with 'id' and 'name'
      url: data['url'] as String,
      urlToImage: data['urlToImage'] as String,
    );
  }

  // Method to convert 'publishedAt' String to DateTime for displaying
  DateTime getFormattedPublishedAt() {
    return DateTime.parse(publishedAt); // Convert String to DateTime
  }

  // Convert BlogData to a Map for saving back to Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'content': content,
      'description': description,
      'publishedAt': publishedAt,
      'source': source,
      'url': url,
      'urlToImage': urlToImage,
    };
  }
}

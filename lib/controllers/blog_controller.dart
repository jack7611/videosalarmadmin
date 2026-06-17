import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BlogController extends GetxController {
  var blogData = <Map<String, dynamic>>[].obs;
  var isLoading = true.obs;
  var error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBlogs();
  }

  // Fetch data from Firestore
  void fetchBlogs() async {
    try {
      isLoading.value = true;
      final snapshot = await FirebaseFirestore.instance.collection('blogsnew').get();
      var blogs = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'author': data['author'],
          'content': data['content_en'] ?? data['content'],
          'description': data['description_en'] ?? data['description'],
          'description_en': data['description_en'] ?? data['description'],
          'description_hi': data['description_hi'],
          'publishedAt': data['publishedAt'],
          'source': data['source'],
          'title': data['title_en'] ?? data['title'],
          'title_en': data['title_en'] ?? data['title'],
          'title_hi': data['title_hi'],
          'url': data['url'],
          'urlToImage': data['urlToImage'],
        };
      }).toList();

      blogData.value = blogs;
    } catch (e) {
      print("Error fetching blogs: $e");
      error.value = "Failed to fetch blogs: $e";
    } finally {
      isLoading.value = false;
    }
  }

  // Convert 'publishedAt' string to DateTime
  DateTime convertPublishedAtToDateTime(String publishedAt) {
    try {
      return DateTime.parse(publishedAt);  // Convert string to DateTime
    } catch (e) {
      print("Error converting 'publishedAt' to DateTime: $e");
      return DateTime.now();  // Return current date in case of error
    }
  }

  // Format DateTime to a readable format
  String formatPublishedAt(String publishedAt) {
    DateTime dateTime = convertPublishedAtToDateTime(publishedAt);
    return DateFormat('yyyy-MM-dd').format(dateTime);  // Format to 'yyyy-MM-dd'
  }

  // Delete blog post by ID
  Future<void> deleteBlog(String id) async {
    try {
      await FirebaseFirestore.instance.collection('blogsnew').doc(id).delete();
      fetchBlogs();
      blogData.removeWhere((blog) => blog['id'] == id);
    } catch (e) {
      print("Error deleting blog: $e");
    }
  }

  // Add a new blog post
  Future<void> addBlog(String title, String description, String content, String author, String source, String url, String urlToImage, String publishedAt) async {
    if (_isInputInvalid(title, description, content, author, url)) {
      return;  // Early return if inputs are invalid
    }

    try {
      var newDocRef = await FirebaseFirestore.instance.collection('blogsnew').add({
        'title': title,
        'description': description,
        'content': content,
        'author': author,
        'source': source,
        'url': url,
        'urlToImage': urlToImage,
        'publishedAt': publishedAt,
      });

      // Add new blog to the local list
      blogData.add({
        'id': newDocRef.id,
        'title': title,
        'description': description,
        'content': content,
        'author': author,
        'source': source,
        'url': url,
        'urlToImage': urlToImage,
        'publishedAt': publishedAt,
      });
      fetchBlogs();
    } catch (e) {
      _handleError("Error adding blog", e);
    }
  }

   // Method to update an existing blog in Firebase
Future<void> updateBlog({
  required String blogId,
  required Map<String, dynamic> updatedFields,
}) async {
  try {
    // Update only the specified fields in Firebase
    await FirebaseFirestore.instance.collection('blogsnew').doc(blogId).update(updatedFields);

    // Update the local list with the modified fields
    int index = blogData.indexWhere((blog) => blog['id'] == blogId);
    if (index != -1) {
      blogData[index].addAll(updatedFields); // Merge updated fields with the existing blog data
    }

    fetchBlogs(); // Refresh the blog list after update
  } catch (e) {
    print("Error updating blog: $e");
    error.value = "Failed to update blog: $e";
  }
}


 bool _isInputInvalid(String title, String description, String content, String author, String url) {
    if ([title, description, content, author, url].any((value) => value.isEmpty)) {
      error.value = "All fields must be filled.";
      return true;
    }
    return false;
  }

  // Handle errors and update the `error` observable
  void _handleError(String message, Object error) {
    this.error.value = "$message: $error";
    print("$message: $error");  // Log for debugging
  }
}

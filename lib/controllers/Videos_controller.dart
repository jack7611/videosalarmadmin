import 'package:admin/models/Videos.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideosController extends GetxController {
  var videos = <VideoData>[].obs;
  var isLoading = true.obs;
  var error = ''.obs;

  @override
  void onInit() {
    fetchVideos();
    super.onInit();
  }

  /// Fetch all videos from Firestore and update the local list
  ///   // Fetch videos by category from Firestore

  Future<void> fetchVideos() async {
    try {
      isLoading.value = true;

      var querySnapshot = await FirebaseFirestore.instance.collection('videos').get();
      var fetchedVideos = querySnapshot.docs
          .map((doc) => VideoData.fromFirestore(doc))
          .toList();

      videos.assignAll(fetchedVideos);
    } catch (e) {
      _handleError("Error fetching videos", e);
    } finally {
      isLoading.value = false;
    }
  }

Future<void> addVideo(String title, String description, String category, String thumbnailUrl, String videoUrl) async {
  // Debug: Print input parameters to verify the method inputs
  print("Adding video...");
  print("Title: $title, Description: $description, Category: $category, Thumbnail URL: $thumbnailUrl, Video URL: $videoUrl");

  if (_isInputInvalid(title, description, category, thumbnailUrl, videoUrl)) {
    print("Input validation failed");
    return;  // Early return if inputs are invalid
  }

  try {
    // Debug: Before adding to Firestore
    print("Attempting to add video to Firestore...");

    var newDocRef = await FirebaseFirestore.instance.collection('videos').add({
      'title': title,
      'description': description,
      'category': category,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'createdAt': FieldValue.serverTimestamp(), // Firebase server timestamp
    });

    // Debug: Successfully added video to Firestore
    print("Video added successfully with document ID: ${newDocRef.id}");

    // Update local list with new video data (Optional: you can use the timestamp returned from Firestore if needed)
    videos.add(VideoData(
      id: newDocRef.id,
      title: title,
      description: description,
      category: category,
      thumbnailUrl: thumbnailUrl,
      videoUrl: videoUrl,
      createdAt: DateTime.now(), // Local timestamp (optional)
    ));

    // Debug: Local list updated
    print("Local list updated with new video.");

  } catch (e) {
    // Debug: Catching any error during the process
    _handleError("Error adding video", e);
    print("Error details: $e");
  }
}

  Future<void> fetchVideosByCategory(String category) async {
    try {
      isLoading.value = true;

      var querySnapshot = await FirebaseFirestore.instance
          .collection('videos')
          .where('category', isEqualTo: category)
          .get();
      
      var fetchedVideos = querySnapshot.docs
          .map((doc) => VideoData.fromFirestore(doc))
          .toList();

      videos.assignAll(fetchedVideos);
    } catch (e) {
      _handleError("Error fetching videos by category", e);
    } finally {
      isLoading.value = false;
    }
  }
  /// Update an existing video by `videoUrl`
  
  /// Delete a video by `videoUrl`
  Future<void> deleteVideo(String videoUrl) async {
    try {
      var docId = await _getDocumentIdByVideoUrl(videoUrl);
      if (docId == null) {
        error.value = "Video not found with videoUrl: $videoUrl";
        return;
      }

      await FirebaseFirestore.instance.collection('videos').doc(docId).delete();

      videos.removeWhere((video) => video.videoUrl == videoUrl);
    } catch (e) {
      _handleError("Error deleting video", e);
    }
  }
/// Update an existing video by `videoUrl`
Future<void> updateVideo(String videoUrl, String title, String description, String category, String thumbnailUrl, String newVideoUrl) async {
  if (_isInputInvalid(title, description, category, thumbnailUrl, newVideoUrl)) return;

  try {
    var docId = await _getDocumentIdByVideoUrl(videoUrl);
    if (docId == null) {
      error.value = "Video not found with videoUrl: $videoUrl";
      return;
    }

    // Update Firestore document with new values including server timestamp
    await FirebaseFirestore.instance.collection('videos').doc(docId).update({
      'title': title,
      'description': description,
      'category': category,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': newVideoUrl,
      'createdAt': FieldValue.serverTimestamp(), // Add server timestamp for updated time
    });

    // Update the local list with the new video data and timestamp
    var index = videos.indexWhere((video) => video.videoUrl == videoUrl);
    if (index != -1) {
      videos[index] = VideoData(
        id: docId,
        title: title,
        description: description,
        category: category,
        thumbnailUrl: thumbnailUrl,
        videoUrl: newVideoUrl,
        createdAt: DateTime.now(), // Use local timestamp (optional) for updating locally
      );
    }
  } catch (e) {
    _handleError("Error updating video", e);
  }
}

  // --- Helper Methods ---

  /// Find the document ID in Firestore by `videoUrl`
  Future<String?> _getDocumentIdByVideoUrl(String videoUrl) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('videos')
        .where('videoUrl', isEqualTo: videoUrl)
        .get();

    return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.id : null;
  }

  /// Validate inputs to prevent empty or invalid data
  bool _isInputInvalid(String title, String description, String category, String thumbnailUrl, String videoUrl) {
    if ([title, description, category, thumbnailUrl, videoUrl].any((value) => value.isEmpty)) {
      error.value = "All fields must be filled.";
      return true;
    }
    return false;
  }

  /// Handle errors and update the `error` observable
  void _handleError(String message, Object error) {
    this.error.value = "$message: $error";
    print("$message: $error"); // Log for debugging
  }
}


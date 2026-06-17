import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin/models/Movies.dart';
import 'dart:html' as html;

class CreatorMovieController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var movies = <Movie>[].obs;
  var isLoading = true.obs;
  var error = ''.obs;
  var ratePerWatchHour = 50.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCreatorMovies();
    fetchWatchHourRate();
  }

  Future<void> fetchWatchHourRate() async {
    try {
      final doc = await _firestore.collection('settings').doc('earnings').get();
      if (doc.exists && doc.data()?['ratePerWatchHour'] != null) {
        ratePerWatchHour.value =
            (doc.data()!['ratePerWatchHour'] as num).toDouble();
      }
    } catch (_) {}
  }

  // Future<void> fetchCreatorMovies() async {
  //   try {
  //     isLoading.value = true;
  //     String? creatorId = html.window.localStorage['creatorId'];

  //     if (creatorId == null) {
  //       error.value = "Creator ID not found. Please log in again.";
  //       return;
  //     }

  //     final snapshot = await _firestore
  //         .collection('newvideos')
  //         .where('creatorId', isEqualTo: creatorId)
  //         .get();

  //     var fetchedMovies = snapshot.docs
  //         .map((doc) => Movie.fromFirestore(doc.id, doc.data()))
  //         .toList();
  //         print("Fetched Movies : $fetchedMovies");

  //     // Client-side sorting to avoid creating a composite index in Firestore
  //     fetchedMovies.sort((a, b) {
  //       Timestamp tA = a.createdAt ?? Timestamp.now();
  //       Timestamp tB = b.createdAt ?? Timestamp.now();
  //       return tB.compareTo(tA); // Descending order (newest first)
  //     });

  //     movies.value = fetchedMovies;

  //     error.value = '';
  //   } catch (e) {
  //     error.value = 'Failed to fetch movies: $e';
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }


  Future<void> fetchCreatorMovies() async {
    try {
      isLoading.value = true;
      String? creatorId = html.window.localStorage['creatorId'];

      if (creatorId == null) {
        error.value = "Creator ID not found. Please log in again.";
        return;
      }

      final snapshot = await _firestore
          .collection('newvideos')
          .where('creatorId', isEqualTo: creatorId)
          .get();

      var fetchedMovies = snapshot.docs
          .map((doc) => Movie.fromFirestore(doc.id, doc.data()))
          .toList();
     

      // Client-side sorting to avoid creating a composite index in Firestore
      fetchedMovies.sort((a, b) {
        Timestamp tA = _toTimestamp(a.createdAt);
        Timestamp tB = _toTimestamp(b.createdAt);
        return tB.compareTo(tA); // Descending order (newest first)
      });

      movies.value = fetchedMovies;
      error.value = '';
    } catch (e) {
      error.value = 'Failed to fetch movies: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Safely converts String, Timestamp, or null to a Timestamp
  Timestamp _toTimestamp(dynamic value) {
    if (value == null) return Timestamp.now();
    if (value is Timestamp) return value;
    if (value is String) {
      try {
        final dateTime = DateTime.parse(value);
        return Timestamp.fromDate(dateTime);
      } catch (_) {
        return Timestamp.now();
      }
    }
    return Timestamp.now();
  }
}

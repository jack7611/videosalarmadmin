import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin/models/Movies.dart';

class MovieController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var movies = <Movie>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMovies();
  }

  // ---------------- FETCH ----------------

  Future<void> fetchMovies() async {
    try {
      isLoading.value = true;

      final snapshot = await _firestore
          .collection('movies')
          .orderBy('createdAt', descending: true)
          .get();

      movies.value = snapshot.docs
          .map((doc) => Movie.fromFirestore(doc.id, doc.data()))
          .toList();

      error.value = '';
    } catch (e) {
      error.value = 'Failed to fetch movies: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------- CREATE ----------------

  Future<void> createMovie(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;

      await _firestore.collection('movies').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        //'releaseDate': FieldValue.serverTimestamp(),
      });

      await fetchMovies();
    } catch (e) {
      throw Exception('Create movie failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------- UPDATE ----------------

  Future<void> updateMovie({
    required String movieId,
    required Map<String, dynamic> data,
  }) async {
    try {
      isLoading.value = true;

      await _firestore
          .collection('movies')
          .doc(movieId)
          .update(data);

      await fetchMovies();
    } catch (e) {
      throw Exception('Update movie failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------- DELETE ----------------

  Future<void> deleteMovie(String movieId) async {
    try {
      await _firestore.collection('movies').doc(movieId).delete();
      await fetchMovies();
    } catch (e) {
      throw Exception('Delete movie failed: $e');
    }
  }
}

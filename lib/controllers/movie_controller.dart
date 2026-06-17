import 'dart:math';
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

      // No orderBy — legacy docs have createdAt as String, new docs as
      // Timestamp. Mixing types breaks Firestore orderBy, so sort client-side.
      final snapshot = await _firestore.collection('newvideos').get();

      final list = snapshot.docs
          .map((doc) => Movie.fromFirestore(doc.id, doc.data()))
          .toList()
        ..sort((a, b) {
          final aMs = _createdAtMs(a.createdAt);
          final bMs = _createdAtMs(b.createdAt);
          return bMs.compareTo(aMs); // newest first
        });

      movies.value = list;
      error.value = '';
    } catch (e) {
      error.value = 'Failed to fetch movies: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Converts Timestamp or null to ms-since-epoch; null → 0 (sorts last).
  int _createdAtMs(dynamic createdAt) {
    if (createdAt == null) return 0;
    if (createdAt is Timestamp) return createdAt.millisecondsSinceEpoch;
    return 0;
  }

  // ---------------- CREATE ----------------

  // Builds a doc ID that always sorts ABOVE all existing ones in Firebase
  // console (alphabetical order by doc ID).
  //
  // Pattern used by the previous admin:  NNNxxxxxxxxxxxxxxxx
  //   NNN = 3-digit zero-padded counter that DECREMENTS on every new upload
  //   xxx = 17 random Firestore-style chars (same length as a real auto-ID)
  //
  // Example sequence:
  //   existing min → 005BsCuzasLOnwh1p9oD
  //   new upload   → 004<random>          ← sorts above 005 alphabetically
  //   next upload  → 003<random>          ← sorts above 004
  //
  // Falls back to "000<random>" once the counter would go below 0.
  Future<String> _newDocId() async {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random();
    String randomSuffix() =>
        List.generate(17, (_) => chars[rng.nextInt(chars.length)]).join();

    try {
      // Read all doc IDs and find the current minimum 3-digit numeric prefix.
      final snapshot = await _firestore.collection('newvideos').get();
      final prefixRe = RegExp(r'^\d{3}');
      int minPrefix = 999; // default if no sequential docs exist yet

      for (final doc in snapshot.docs) {
        final m = prefixRe.firstMatch(doc.id);
        if (m != null) {
          final n = int.parse(m.group(0)!);
          if (n < minPrefix) minPrefix = n;
        }
      }

      // New prefix is one below the current minimum (clamped at 0).
      final newPrefix = (minPrefix - 1).clamp(0, 999);
      final paddedPrefix = newPrefix.toString().padLeft(3, '0');
      return '$paddedPrefix${randomSuffix()}';
    } catch (_) {
      // Fallback: prefix "000" + random suffix still sorts before any "NNN" doc.
      return '000${randomSuffix()}';
    }
  }

  Future<void> createMovie(Map<String, dynamic> data) async {
    try {
      isLoading.value = true;

      final docId = await _newDocId();
      await _firestore.collection('newvideos').doc(docId).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
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
          .collection('newvideos')
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
      await _firestore.collection('newvideos').doc(movieId).delete();
      await fetchMovies();
    } catch (e) {
      throw Exception('Delete movie failed: $e');
    }
  }
}

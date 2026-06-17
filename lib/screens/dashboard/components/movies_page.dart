import 'package:admin/models/Movies.dart';
import 'package:admin/screens/dashboard/components/addmovie_screen.dart';
import 'package:admin/controllers/movie_controller.dart'; 
import 'package:get/get.dart'; // For finding controller
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class MoviesPage extends StatelessWidget {
  const MoviesPage({super.key});
 
  @override
  Widget build(BuildContext context) {
    final MovieController moviesController = Get.put(MovieController());
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Movies Management",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextButton.icon(
              onPressed: () => moviesController.fetchMovies(),
              icon: const Icon(Icons.refresh_rounded,
                  size: 20, color: Colors.white70),
              label: const Text(
                'Refresh',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A2A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddmovieScreen(),
                    ));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add Movies',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Video Library Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Movies Library",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Manage your video collection • Newest first",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// Table Header
            _tableHeader(),

            /// Table Rows
            Expanded(
              child: StreamBuilder(
                // No orderBy — mixed createdAt types (String vs Timestamp)
                // in legacy docs break Firestore ordering. Sort client-side.
                stream: FirebaseFirestore.instance
                    .collection('newvideos')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No movies found",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  // Client-side sort: newest createdAt first.
                  // Handles Timestamp, ISO-8601 String, and missing field.
                  final docs = List.of(snapshot.data!.docs)
                    ..sort((a, b) {
                      final aMs = _docCreatedAtMs(
                          a.data() as Map<String, dynamic>);
                      final bMs = _docCreatedAtMs(
                          b.data() as Map<String, dynamic>);
                      return bMs.compareTo(aMs); // descending
                    });

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final movie = Movie.fromFirestore(
                        docs[index].id,
                        docs[index].data() as Map<String, dynamic>,
                      );
                      return VideoRow(
                        srNo: index + 1,
                        id: movie.id,
                        title: movie.titleText,
                        category: movie.categoryText,
                        director: movie.directorText,
                        year: movie.yearText,
                        duration: movie.durationText,
                        views: _formatViews(movie.viewsCount),
                        thumbnailUrl: movie.thumbnailUrl ?? '',
                        isPopular: movie.viewsCount > 1000,
                        isShown: movie.active,
                        movieModel: movie,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: const Color(0xFF020617),
      child: const Row(
        children: [
          _HeaderCell("#", flex: 1),
          _HeaderCell("Title", flex: 3),
          _HeaderCell("Category", flex: 2),
          _HeaderCell("Director", flex: 3),
          _HeaderCell("Year", flex: 1),
          _HeaderCell("Duration", flex: 2),
          _HeaderCell("Views", flex: 2),
          _HeaderCell("Thumbnail", flex: 2),
          _HeaderCell("Actions", flex: 2),
          _HeaderCell("Show", flex: 1),
        ],
      ),
    );
  }
}

String _formatViews(int views) {
  if (views >= 1000000) {
    return "${(views / 1000000).toStringAsFixed(1)}M";
  } else if (views >= 1000) {
    return "${(views / 1000).toStringAsFixed(1)}K";
  }
  return views.toString();
}

// Returns milliseconds from epoch for a doc's createdAt field.
// Handles Firestore Timestamp, ISO-8601 String, and missing/null — returns 0
// for missing so those docs sort to the bottom.
int _docCreatedAtMs(Map<String, dynamic> data) {
  final raw = data['createdAt'];
  if (raw == null) return 0;
  if (raw is Timestamp) return raw.millisecondsSinceEpoch;
  if (raw is String) {
    try {
      return DateTime.parse(raw).millisecondsSinceEpoch;
    } catch (_) {
      return 0;
    }
  }
  return 0;
}

/// --------------------
/// Video Row Widget
/// --------------------
class VideoRow extends StatelessWidget {
  final int srNo;
  final String id;
  final String title;
  final String category;
  final String director;
  final String year;
  final String duration;
  final String views;
  final bool isPopular;
  final bool isShown;
  final String thumbnailUrl;
  final Movie movieModel;

  const VideoRow({
    super.key,
    required this.srNo,
    required this.id,
    required this.title,
    required this.category,
    required this.director,
    required this.year,
    required this.duration,
    required this.views,
    required this.thumbnailUrl,
    required this.movieModel,
    this.isPopular = false,
    this.isShown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isPopular ? const Color(0xFF3F3F46) : const Color(0xFF1E293B),
      ),
      child: Row(
        children: [
          // Serial number
          Expanded(
            flex: 1,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$srNo',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isPopular)
                  const Text(
                    "Most Popular",
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          _cell(category, flex: 2, badge: true),
          _cell(director, flex: 3),
          _cell(year, flex: 1),
          _cell(duration, flex: 2),
          _cell(views, flex: 2, icon: Icons.remove_red_eye),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                _showThumbnailPreview(context, thumbnailUrl.replaceAll('\n', '').trim());
              },
              child: const Text(
                "Preview",
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          /// ✅ Show Toggle Column
          Expanded(
            flex: 1,
            child: Switch(
              value: isShown,
              onChanged: (value) async {
                await FirebaseFirestore.instance
                    .collection('newvideos')
                    .doc(id)
                    .update({'isShown': value});
              },
              activeColor: Colors.green,
            ),
          ),
          _actions(context),
        ],
      ),
    );
  }

  Widget _cell(
    String text, {
    required int flex,
    bool badge = false,
    bool link = false,
    IconData? icon,
  }) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          if (icon != null)
            const Icon(Icons.remove_red_eye, size: 14, color: Colors.white54),
          if (icon != null) const SizedBox(width: 4),
          Container(
            padding: badge
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : EdgeInsets.zero,
            decoration: badge
                ? BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Text(
              text,
              style: TextStyle(
                color: link ? Colors.blueAccent : Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
  return Expanded(
    flex: 2,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {
            // Open AddmovieScreen in edit mode with the movie data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddmovieScreen(
                  movie: movieModel,
                ),
              ),
            );
          },
          child: const _ActionIcon(Icons.edit, Colors.orange),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Delete Movie"),
                content: const Text(
                    "Are you sure you want to delete this movie? This action cannot be undone."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Get.find<MovieController>().deleteMovie(id).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Movie deleted successfully")),
                        );
                      }).catchError((e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      });
                    },
                    child: const Text("Delete",
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          child: const _ActionIcon(Icons.delete, Colors.red),
        ),
      ],
    ),
  );
}


}

/// --------------------
/// Small Widgets
/// --------------------
class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _ActionIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

void _showThumbnailPreview(BuildContext context, String thumbnailUrl) {
  if (thumbnailUrl.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No thumbnail available")),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: FutureBuilder<String>(
          future: FirebaseStorage.instance
              .ref(thumbnailUrl)
              .getDownloadURL(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 60),
              );
            }

            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      snapshot.data!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

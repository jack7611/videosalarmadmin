import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/models/Movies.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:admin/constants.dart';
import 'package:get/get.dart';
import 'package:admin/creators/screens/creator_movie_detail_screen.dart';

String _formatWatchTime(int secs) {
  if (secs <= 0) return '0m';
  if (secs < 60) return '${secs}s';
  if (secs < 3600) return '${secs ~/ 60}m';
  final h = secs ~/ 3600;
  final m = (secs % 3600) ~/ 60;
  return '${h}h ${m}m';
}

Widget _statBadge(
    {required IconData icon,
    required String label,
    required Color color}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    ]),
  );
}

class CreatorMovieCard extends StatelessWidget {
  final Movie movie;

  const CreatorMovieCard({Key? key, required this.movie}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
// Thumbnail Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: movie.thumbnailUrl != null &&
                          movie.thumbnailUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.thumbnailUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: const Center(
                                child: Icon(Icons.image_not_supported,
                                    size: 50, color: Colors.white54)),
                          ),
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Center(
                              child: Icon(Icons.image_not_supported_outlined,
                                  size: 50, color: Colors.white54)),
                        ),
                ),
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(10)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  movie.titleText.isNotEmpty ? movie.titleText : "Untitled",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Release Year
                Text(
                  movie.yearText,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                // Views & Watch Time stats
                Row(
                  children: [
                    _statBadge(
                      icon: Icons.visibility_rounded,
                      label: '${movie.viewsCount}',
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    _statBadge(
                      icon: Icons.access_time_rounded,
                      label: _formatWatchTime(movie.watchSecondsCount),
                      color: Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // View Details Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(() => CreatorMovieDetailScreen(movie: movie));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      "View Details",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

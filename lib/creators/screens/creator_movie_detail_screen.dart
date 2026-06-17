import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin/models/Movies.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:admin/constants.dart';
import 'package:intl/intl.dart';

class CreatorMovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const CreatorMovieDetailScreen({Key? key, required this.movie})
      : super(key: key);

  @override
  State<CreatorMovieDetailScreen> createState() =>
      _CreatorMovieDetailScreenState();
}

class _CreatorMovieDetailScreenState extends State<CreatorMovieDetailScreen> {
  ChewieController? _chewieController;
  VideoPlayerController? _videoPlayerController;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Player initializes on user action
  }

  void _initializePlayer() async {
    if (widget.movie.videoUrl != null && widget.movie.videoUrl!.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      try {
        _videoPlayerController =
            VideoPlayerController.network(widget.movie.videoUrl!);
        await _videoPlayerController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9,
          placeholder: const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );
        setState(() {
          _isPlaying = true;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  String _formatWatchTime(int secs) {
    if (secs <= 0) return '0m';
    if (secs < 60) return '${secs}s';
    if (secs < 3600) return '${secs ~/ 60}m ${secs % 60}s';
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(widget.movie.titleText,
            style: GoogleFonts.poppins(fontSize: 18)),
        backgroundColor: secondaryColor,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsBar(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildLeftColumn()),
                            const SizedBox(width: 40),
                            Expanded(flex: 2, child: _buildRightColumn()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLeftColumn(),
                            const SizedBox(height: 32),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 32),
                            _buildRightColumn(),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsBar() {
    final views = widget.movie.viewsCount;
    final watchSecs = widget.movie.watchSecondsCount;
    final watchTime = _formatWatchTime(watchSecs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(children: [
        _statCell(
          icon: Icons.visibility_rounded,
          value: '$views',
          label: 'Total Views',
          color: Colors.blueAccent,
        ),
        _statDivider(),
        _statCell(
          icon: Icons.access_time_rounded,
          value: watchTime,
          label: 'Watch Time',
          color: Colors.amber,
        ),
        _statDivider(),
        _statCell(
          icon: Icons.trending_up_rounded,
          value: views > 500
              ? 'Trending'
              : views > 100
                  ? 'Growing'
                  : 'New',
          label: 'Status',
          color: Colors.greenAccent,
        ),
      ]),
    );
  }

  Widget _statCell(
      {required IconData icon,
      required String value,
      required String label,
      required Color color}) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _statDivider() =>
      Container(width: 1, height: 56, color: Colors.white12);

  // --- Components ---

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          widget.movie.titleText,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        // Metadata List
        _buildMetaRow(Icons.category, "Category:", widget.movie.categoryText),
        _buildMetaRow(Icons.verified_user, "CBFC Rating:", widget.movie.cbfc?['en'] ?? "N/A"),
        _buildMetaRow(Icons.person, "Director:", widget.movie.directorText),
        _buildMetaRow(Icons.timer, "Duration:", widget.movie.durationText),
        _buildMetaRow(Icons.calendar_today, "Release Year:", widget.movie.yearText),
        _buildMetaRow(Icons.star, "Starcast:", widget.movie.starcast?['en'] ?? "N/A", isLongText: true),
        _buildMetaRow(Icons.visibility, "Total Views:", "${widget.movie.viewsCount}"),
        _buildMetaRow(Icons.access_time, "Watch Time:", _formatWatchTime(widget.movie.watchSecondsCount)),
        _buildMetaRow(Icons.add_circle, "Created:", _formatDate(widget.movie.createdAt)),
        _buildMetaRow(Icons.update, "Released:", _formatDate(widget.movie.releaseDate)),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video / Thumbnail Section (Top of Right Column)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          child: _isPlaying && _chewieController != null
              ? AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Chewie(controller: _chewieController!),
                )
              : _isLoading
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()))
                  : widget.movie.thumbnailUrl != null
                      ? AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(widget.movie.thumbnailUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
        ),

        Text(
          "Description",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.movie.description?['en'] ?? "No description available.",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white70,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // Video Action Button (Hidden when playing)
        if (!_isPlaying)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _initializePlayer,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                "Watch Video",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value,
      {bool isLongText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 16),
          // Label
          SizedBox(
            width: 120, 
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ),
          // Value
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: isLongText ? 5 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    try {
      DateTime date = timestamp.toDate();
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return "N/A";
    }
  }
}

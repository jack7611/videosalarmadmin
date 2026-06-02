import 'package:admin/screens/dashboard/components/Edit_videos.dart';
import 'package:admin/screens/dashboard/components/VideosDetail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart';

const Color darkScaffoldBackground = Color(0xFF1A202C);
const Color darkCardBackground = Color(0xFF2D3748);
const Color primaryTextColor = Color(0xFFF7FAFC);
const Color secondaryTextColor = Color(0xFFA0AEC0);
const Color subtleTextColor = Color(0xFF718096);

class VideosPage extends StatelessWidget {
  const VideosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: const Text(
          "Videos Management",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A202C),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('bunny').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: TextStyle(fontSize: 18, color: Colors.red[300]),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading videos...',
                      style: TextStyle(fontSize: 16, color: secondaryTextColor),
                    ),
                  ],
                ),
              );
            }

            final videos = snapshot.data!.docs
                .map((doc) => BunnyVideo.fromFirestore(doc))
                .toList();

            videos.sort((a, b) => b.views.compareTo(a.views));

            return Column(
              children: [
                VideosSummaryCards(videos: videos),
                const SizedBox(height: 24),
                Expanded(
                  child: VideosPageTable(videos: videos),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class VideosSummaryCards extends StatelessWidget {
  const VideosSummaryCards({Key? key, required this.videos}) : super(key: key);

  final List<BunnyVideo> videos;

  @override
  Widget build(BuildContext context) {
    final totalVideos = videos.length;
    final totalViews = videos.fold<int>(0, (sum, video) => sum + video.views);
    final mostPopular = videos.isNotEmpty ? videos.first : null;
    final categories = videos.map((v) => v.category).toSet().length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Videos',
            value: totalVideos.toString(),
            icon: Icons.video_library,
            color: const Color(0xFF4299E1),
            subtitle: '${categories} categories',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Total Views',
            value: _formatNumber(totalViews),
            icon: Icons.visibility,
            color: const Color(0xFF48BB78),
            subtitle: 'All time views',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Most Popular',
            value: mostPopular?.title ?? 'No videos',
            icon: Icons.star,
            color: const Color(0xFFED8936),
            subtitle: mostPopular != null ? '${_formatNumber(mostPopular!.views)} views' : '',
            isPopular: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Average Views',
            value: totalVideos > 0 ? _formatNumber((totalViews / totalVideos).round()) : '0',
            icon: Icons.trending_up,
            color: const Color(0xFF9F7AEA),
            subtitle: 'Per video',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    bool isPopular = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkCardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isPopular ? Border.all(color: const Color(0xFFED8936), width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (isPopular) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFED8936),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'TOP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: subtleTextColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class VideosPageTable extends StatelessWidget {
  const VideosPageTable({Key? key, required this.videos}) : super(key: key);

  final List<BunnyVideo> videos;

  void _launchURL(String url) {
    html.window.open(url, '_blank');
  }

  void _showDeleteConfirmationDialog(BuildContext context, String videoId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 30, 36, 42),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[400]),
              const SizedBox(width: 8),
              const Text("Delete Video", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "Are you sure you want to delete this video? This action cannot be undone.",
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('bunny')
                    .doc(videoId)
                    .delete();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkCardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Video Library',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    Text(
                      'Manage your video collection • Sorted by views',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        dataRowMaxHeight: 80,
                        columnSpacing: 24,
                        headingRowColor: MaterialStateProperty.resolveWith(
                          (states) => const Color(0xFF1A202C),
                        ),
                        headingRowHeight: 56,
                        columns: const [
                          DataColumn(
                            label: Text(
                              "Title",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Category",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Director",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Year",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Duration",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Row(
                              children: [
                                Icon(Icons.trending_up, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "Views",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Thumbnail",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Actions",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                        rows: videos.asMap().entries.map((entry) {
                          int index = entry.key;
                          BunnyVideo video = entry.value;
                          bool isTopVideo = index == 0 && videos.isNotEmpty;

                          return DataRow(
                            color: MaterialStateProperty.resolveWith((states) {
                              if (isTopVideo) {
                                return const Color(0xFFED8936).withOpacity(0.15);
                              }
                              return index.isEven
                                  ? darkCardBackground.withOpacity(0.5)
                                  : Colors.transparent;
                            }),
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    if (isTopVideo) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFED8936),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '#1',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            video.title,
                                            style: TextStyle(
                                              fontWeight: isTopVideo ? FontWeight.w600 : FontWeight.w500,
                                              fontSize: 14,
                                              color: primaryTextColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                          if (isTopVideo) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Most Popular',
                                              style: TextStyle(
                                                 fontSize: 11,
                                                color: Colors.orange[300],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4299E1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    video.category,
                                    style: const TextStyle(
                                      color: Color(0xFF4299E1),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(
                                video.director,
                                style: const TextStyle(fontSize: 14, color: secondaryTextColor),
                              )),
                              DataCell(Text(
                                video.releaseYear,
                                style: const TextStyle(fontSize: 14, color: secondaryTextColor),
                              )),
                              DataCell(Text(
                                video.duration,
                                style: const TextStyle(fontSize: 14, color: secondaryTextColor),
                              )),
                              DataCell(
                                Row(
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      size: 16,
                                      color: isTopVideo ? Colors.orange[300] : secondaryTextColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatNumber(video.views),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isTopVideo ? FontWeight.w600 : FontWeight.w500,
                                        color: isTopVideo ? Colors.orange[300] : secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                TextButton.icon(
                                  onPressed: () => _launchURL(video.thumbnailUrl),
                                  icon: const Icon(Icons.image, size: 16),
                                  label: const Text("Preview"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF4299E1),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.visibility_outlined,
                                      color: const Color(0xFF4299E1),
                                      onPressed: () {
                                        Get.to(() => ViewDetailsPage(video: video));
                                      },
                                      tooltip: 'View Details',
                                    ),
                                    const SizedBox(width: 4),
                                    _buildActionButton(
                                      icon: Icons.edit_outlined,
                                      color: const Color(0xFFED8936),
                                      onPressed: () {
                                        Get.to(() => EditVideoPage(videoId: video.id));
                                      },
                                      tooltip: 'Edit Video',
                                    ),
                                    const SizedBox(width: 4),
                                    _buildActionButton(
                                      icon: Icons.delete_outline,
                                      color: const Color(0xFFE53E3E),
                                      onPressed: () {
                                        _showDeleteConfirmationDialog(context, video.id);
                                      },
                                      tooltip: 'Delete Video',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class ViewDetailsPage extends StatelessWidget {
  final BunnyVideo video;
  const ViewDetailsPage({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkScaffoldBackground,
      appBar: AppBar(
        title: Text(
          video.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A202C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          color: darkCardBackground,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: ListView(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Category', video.category, Icons.category),
                          _buildDetailRow('CBFC Rating', video.cbfc, Icons.verified_user),
                          _buildDetailRow('Director', video.director, Icons.person),
                          _buildDetailRow('Duration', video.duration, Icons.schedule),
                          _buildDetailRow('Release Year', video.releaseYear, Icons.calendar_today),
                          _buildDetailRow('Starcast', video.starcast, Icons.stars),
                          // _buildDetailRow('Views', _formatNumber(video.views), Icons.visibility),
                          _buildDetailRow('Created', DateFormat.yMMMd().format(video.createdAt.toDate()), Icons.add_circle),
                          _buildDetailRow('Released', DateFormat.yMMMd().format(video.releaseDate.toDate()), Icons.event),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            video.description.isEmpty ? 'No description available' : video.description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: secondaryTextColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                html.window.open(video.videoUrl, '_blank');
                              },
                              icon: const Icon(Icons.play_arrow, color: Colors.white),
                              label: const Text(
                                'Watch Video',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4299E1),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF4299E1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF4299E1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class BunnyVideo {
  final String id;
  final String category;
  final String cbfc;
  final Timestamp createdAt;
  final String description;
  final String director;
  final String duration;
  final bool myList;
  final Timestamp releaseDate;
  final String releaseYear;
  final String starcast;
  final String thumbnailUrl;
  final String title;
  final String videoUrl;
  final int views;

  BunnyVideo({
    required this.id,
    required this.category,
    required this.cbfc,
    required this.createdAt,
    required this.description,
    required this.director,
    required this.duration,
    required this.myList,
    required this.releaseDate,
    required this.releaseYear,
    required this.starcast,
    required this.thumbnailUrl,
    required this.title,
    required this.videoUrl,
    required this.views,
  });

  factory BunnyVideo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BunnyVideo(
      id: doc.id,
      category: data['category'] ?? '',
      cbfc: data['cbfc'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      description: data['description'] ?? '',
      director: data['director'] ?? '',
      duration: data['duration'] ?? '',
      myList: data['myList'] ?? false,
      releaseDate: data['releaseDate'] ?? Timestamp.now(),
      releaseYear: data['releaseYear'] ?? '',
      starcast: data['starcast'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      title: data['title'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      views: data['views'] ?? 0,
    );
  }
}
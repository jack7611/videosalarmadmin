import 'package:admin/screens/dashboard/components/constraints.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoAdsTab extends StatefulWidget {
  final List<Map<String, dynamic>> existingVideoAds;
  final bool isLoadingVideoAds;
  final Function(List<Map<String, dynamic>>) onVideoAdsChanged;
  final Function(bool) onIsLoadingChanged;

  const VideoAdsTab({
    Key? key,
    required this.existingVideoAds,
    required this.isLoadingVideoAds,
    required this.onVideoAdsChanged,
    required this.onIsLoadingChanged,
  }) : super(key: key);

  @override
  State<VideoAdsTab> createState() => _VideoAdsTabState();

  // Ads stored as subcollections: newvideos/{videoId}/ads/{adId}
  static Future<void> loadVideoAds(
    StateSetter setState,
    BuildContext context,
    Function(bool) setIsLoading,
    Function(List<Map<String, dynamic>>) setVideoAds,
  ) async {
    setState(() => setIsLoading(true));

    try {
      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance
              .collectionGroup(videoAdsCollection)
              .get();

      final List<Map<String, dynamic>> videoAds = querySnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
                // parent ref: newvideos/{videoId}/ads/{adId}
                'videoId': doc.reference.parent.parent?.id ?? '',
              })
          .toList();

      setState(() {
        setVideoAds(videoAds);
        setIsLoading(false);
      });
    } catch (e) {
      print("Error loading video ads: $e");
      setState(() {
        setVideoAds([]);
        setIsLoading(false);
      });
    }
  }
}

class _VideoAdsTabState extends State<VideoAdsTab> {
  String? _videoAdUrl;
  // 'pre-roll' | 'mid-roll' | 'post-roll'
  String _videoAdPlacementType = 'pre-roll';
  double _videoAdStartTimestamp = 0;
  double _videoAdEndTimestamp = 30;
  VideoPlayerController? _videoPlayerController;
  String? _selectedVideoToPlaceAdOnId;
  double _videoDuration = 3600; // default 1 hour; updated when target video selected
  bool _isLoadingTargetDuration = false;

  List<Map<String, dynamic>> _availableVideos = [];
  bool _isLoadingAvailableVideos = true;

  String _adDescription = '';

  static const Map<String, String> _placementLabels = {
    'pre-roll': 'Pre-roll (plays before video starts)',
    'mid-roll': 'Mid-roll (plays at custom timestamp)',
    'post-roll': 'Post-roll (plays after video ends)',
  };

  @override
  void initState() {
    super.initState();
    _loadAvailableVideos();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  // ── Target video selection: load actual duration ──────────────────────────
  Future<void> _onTargetVideoSelected(String value) async {
    final selected = _availableVideos.firstWhere(
      (v) => v['videoId'] == value,
      orElse: () => {},
    );
    final url = (selected['videoUrl'] as String?) ?? '';

    setState(() {
      _selectedVideoToPlaceAdOnId = value;
      _isLoadingTargetDuration = url.isNotEmpty;
      _videoDuration = 3600;
      _videoAdStartTimestamp = 0;
      _videoAdEndTimestamp = 30;
    });

    if (url.isNotEmpty) {
      final dur = await _getVideoDuration(url);
      if (mounted) {
        setState(() {
          _videoDuration = dur > 10 ? dur : 3600;
          _isLoadingTargetDuration = false;
        });
      }
    } else {
      setState(() => _isLoadingTargetDuration = false);
    }
  }

  // ── Upload ad ─────────────────────────────────────────────────────────────
  Future<void> _uploadVideoAd() async {
    if (_videoAdUrl == null || _videoAdUrl!.isEmpty) {
      _snack('Please enter the ad video URL.');
      return;
    }
    if (_selectedVideoToPlaceAdOnId == null) {
      _snack('Please select a target video.');
      return;
    }
    if (_adDescription.isEmpty) {
      _snack('Please enter an ad description.');
      return;
    }

    // Compute start/end based on placement type
    double start, end;
    switch (_videoAdPlacementType) {
      case 'pre-roll':
        start = 0;
        end = 30;
        break;
      case 'post-roll':
        start = _videoDuration;
        end = _videoDuration + 30;
        break;
      default: // mid-roll
        start = _videoAdStartTimestamp;
        end = _videoAdEndTimestamp;
        if (end <= start) {
          _snack('End timestamp must be after start timestamp.');
          return;
        }
    }

    // Overlap check — only one equality filter to avoid Firestore index requirement
    try {
      final isOverlapping = await _checkIfAdOverlaps(
          _selectedVideoToPlaceAdOnId!, _videoAdPlacementType);
      if (isOverlapping) {
        _snack('A ${_videoAdPlacementType} ad already exists for this video. Delete it first.');
        return;
      }
    } catch (_) {
      // If overlap check fails, proceed with upload anyway
    }

    try {
      final targetTitle = (_availableVideos.firstWhere(
              (v) => v['videoId'] == _selectedVideoToPlaceAdOnId,
              orElse: () => {'title': ''})['title'] as String?) ??
          '';

      await FirebaseFirestore.instance
          .collection(videosCollection)
          .doc(_selectedVideoToPlaceAdOnId)
          .collection(videoAdsCollection)
          .add({
        'videoUrl': _videoAdUrl!,
        'placement': _videoAdPlacementType,
        'description': _adDescription,
        'startTimestamp': start,
        'endTimestamp': end,
        'videoId': _selectedVideoToPlaceAdOnId,
        'targetVideoTitle': targetTitle,
        'uploadTimestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _videoAdUrl = null;
        _videoAdPlacementType = 'pre-roll';
        _adDescription = '';
        _videoAdStartTimestamp = 0;
        _videoAdEndTimestamp = 30;
        _selectedVideoToPlaceAdOnId = null;
        _videoDuration = 3600;
        _videoPlayerController?.dispose();
        _videoPlayerController = null;
      });

      await VideoAdsTab.loadVideoAds(setState, context,
          widget.onIsLoadingChanged, widget.onVideoAdsChanged);

      _snack('Video ad uploaded successfully!', isError: false);
    } catch (e) {
      _snack('Failed to upload ad: $e');
    }
  }

  // ── Delete ad ─────────────────────────────────────────────────────────────
  Future<void> _deleteVideoAd(String videoId, String adId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF292929),
        title: const Text('Delete Ad', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this ad?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection(videosCollection)
          .doc(videoId)
          .collection(videoAdsCollection)
          .doc(adId)
          .delete();

      await VideoAdsTab.loadVideoAds(setState, context,
          widget.onIsLoadingChanged, widget.onVideoAdsChanged);

      _snack('Ad deleted.', isError: false);
    } catch (e) {
      _snack('Delete failed: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Future<bool> _checkIfAdOverlaps(String videoId, String placementType) async {
    final snap = await FirebaseFirestore.instance
        .collection(videosCollection)
        .doc(videoId)
        .collection(videoAdsCollection)
        .where('placement', isEqualTo: placementType)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> _loadAvailableVideos() async {
    setState(() => _isLoadingAvailableVideos = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection(videosCollection)
          .get();

      final videos = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        final rawTitle = data['title'];
        final titleText = rawTitle is Map
            ? (rawTitle['en'] ?? rawTitle.values.first ?? 'Untitled').toString()
            : (rawTitle ?? 'Untitled').toString();

        final videoUrl = (data['videoUrl2'] as String? ?? '').isNotEmpty
            ? data['videoUrl2'] as String
            : (data['videoUrl'] as String? ?? '');

        videos.add({
          'videoId': doc.id,
          'title': titleText,
          'videoUrl': videoUrl,
          'thumbnailUrl': data['thumbnailUrl'] as String? ?? '',
        });
      }
      setState(() {
        _availableVideos = videos;
        _isLoadingAvailableVideos = false;
      });
    } catch (e) {
      print("Error fetching available videos: $e");
      setState(() => _isLoadingAvailableVideos = false);
    }
  }

  Future<double> _getVideoDuration(String videoUrl) async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await c.initialize();
      final dur = c.value.duration.inSeconds.toDouble();
      await c.dispose();
      return dur;
    } catch (e) {
      print("Error getting video duration: $e");
      return 0;
    }
  }

  void _snack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[800] : Colors.green[700],
    ));
  }

  String _formatTimestamp(double ts) {
    final total = ts.round();
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Upload New Video Ad',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.white) ??
                const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
          ),
          const SizedBox(height: 24),

          // Row 1: Ad URL + Target Video
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Ad Video URL',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: const Color(0xFF292929),
                    prefixIcon:
                        const Icon(Icons.link, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _videoAdUrl = value;
                      _videoPlayerController?.dispose();
                      _videoPlayerController = null;
                      if (Uri.tryParse(value)?.hasAbsolutePath == true &&
                          value.isNotEmpty) {
                        _videoPlayerController =
                            VideoPlayerController.networkUrl(Uri.parse(value))
                              ..initialize().then((_) {
                                if (mounted) setState(() {});
                              });
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildTargetVideoDropdown()),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Description + Placement type
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Ad Description',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: const Color(0xFF292929),
                    prefixIcon: const Icon(Icons.description,
                        color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setState(() => _adDescription = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildPlacementDropdown()),
            ],
          ),
          const SizedBox(height: 16),

          // Mid-roll timestamp slider
          if (_videoAdPlacementType == 'mid-roll') ...[
            if (_isLoadingTargetDuration)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.blueAccent)),
                    SizedBox(width: 10),
                    Text('Loading video duration...',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            else ...[
              Text(
                'Ad trigger position in video  (video length: ${_formatTimestamp(_videoDuration)})',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 6),
              _buildTimestampRangeSlider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Start: ${_formatTimestamp(_videoAdStartTimestamp)}',
                        style: const TextStyle(color: Colors.white70)),
                    Text('End: ${_formatTimestamp(_videoAdEndTimestamp)}',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _videoAdPlacementType == 'pre-roll'
                    ? 'Ad will play at the very start of the selected video (0s–30s).'
                    : 'Ad will play at the very end of the selected video.',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),

          const SizedBox(height: 8),

          // Upload button
          ElevatedButton.icon(
            onPressed: _uploadVideoAd,
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('Upload Video Ad'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),

          // Ad video preview
          if (_videoPlayerController != null &&
              _videoPlayerController!.value.isInitialized)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController!),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {
                    if (_videoPlayerController!.value.isPlaying) {
                      _videoPlayerController!.pause();
                    } else {
                      _videoPlayerController!.play();
                    }
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Icon(
                    _videoPlayerController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Existing ads list
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Text(
            'Existing Video Ads',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.white) ??
                const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: widget.isLoadingVideoAds
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : widget.existingVideoAds.isEmpty
                    ? const Center(
                        child: Text('No video ads yet.',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.separated(
                        itemCount: widget.existingVideoAds.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: Colors.white12),
                        itemBuilder: (context, index) {
                          final ad = widget.existingVideoAds[index];
                          final adId = ad['id'] as String? ?? '';
                          final videoId = ad['videoId'] as String? ?? '';
                          final placement =
                              ad['placement'] as String? ?? 'unknown';
                          final targetTitle =
                              ad['targetVideoTitle'] as String? ?? videoId;
                          final startTs = (ad['startTimestamp'] as num?)
                                  ?.toDouble() ??
                              0.0;
                          final endTs =
                              (ad['endTimestamp'] as num?)?.toDouble() ??
                                  0.0;
                          final desc =
                              ad['description'] as String? ?? '';

                          return Card(
                            color: cardBackgroundColor,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  // Placement chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _placementColor(placement)
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: _placementColor(placement),
                                          width: 1),
                                    ),
                                    child: Text(
                                      placement.toUpperCase(),
                                      style: TextStyle(
                                          color: _placementColor(placement),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          targetTitle.isNotEmpty
                                              ? targetTitle
                                              : 'Video: $videoId',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (desc.isNotEmpty)
                                          Text(desc,
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 12),
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        Text(
                                          placement == 'pre-roll'
                                              ? 'Plays at video start'
                                              : placement == 'post-roll'
                                                  ? 'Plays at video end'
                                                  : '${_formatTimestamp(startTs)} → ${_formatTimestamp(endTs)}',
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete
                                  if (adId.isNotEmpty && videoId.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      tooltip: 'Delete ad',
                                      onPressed: () =>
                                          _deleteVideoAd(videoId, adId),
                                    ),
                                ],
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

  // ── Widgets ───────────────────────────────────────────────────────────────
  Widget _buildPlacementDropdown() {
    return DropdownButtonFormField<String>(
      value: _videoAdPlacementType,
      decoration: InputDecoration(
        labelText: 'Ad Placement Type',
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: const Color(0xFF292929),
        prefixIcon:
            const Icon(Icons.timer_outlined, color: Colors.white70),
      ),
      dropdownColor: const Color(0xFF292929),
      style: const TextStyle(color: Colors.white),
      items: _placementLabels.entries
          .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value,
                    style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: (val) {
        if (val == null) return;
        setState(() {
          _videoAdPlacementType = val;
          _videoAdStartTimestamp = 0;
          _videoAdEndTimestamp = 30;
        });
      },
    );
  }

  Widget _buildTargetVideoDropdown() {
    if (_isLoadingAvailableVideos) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return DropdownButtonFormField<String>(
      value: _selectedVideoToPlaceAdOnId,
      decoration: InputDecoration(
        labelText: 'Target Video',
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: const Color(0xFF292929),
        prefixIcon:
            const Icon(Icons.video_library, color: Colors.white70),
      ),
      dropdownColor: const Color(0xFF292929),
      style: const TextStyle(color: Colors.white),
      hint: const Text('Select a Video',
          style: TextStyle(color: Colors.white70)),
      items: _availableVideos
          .map((v) => DropdownMenuItem<String>(
                value: v['videoId'] as String,
                child: Text(v['title'] as String? ?? 'Unknown',
                    overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) _onTargetVideoSelected(val);
      },
    );
  }

  Widget _buildTimestampRangeSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.blue[700],
        inactiveTrackColor: Colors.grey[600],
        thumbColor: Colors.blueAccent,
        valueIndicatorColor: Colors.blueAccent,
        overlayColor: Colors.blue.withAlpha(32),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),
      child: RangeSlider(
        min: 0.0,
        max: _videoDuration,
        values: RangeValues(
          _videoAdStartTimestamp.clamp(0, _videoDuration),
          _videoAdEndTimestamp.clamp(0, _videoDuration),
        ),
        divisions: (_videoDuration / 10).round().clamp(10, 720),
        labels: RangeLabels(
          _formatTimestamp(_videoAdStartTimestamp),
          _formatTimestamp(_videoAdEndTimestamp),
        ),
        onChanged: (vals) => setState(() {
          _videoAdStartTimestamp = vals.start;
          _videoAdEndTimestamp = vals.end;
        }),
      ),
    );
  }

  Color _placementColor(String placement) {
    switch (placement) {
      case 'pre-roll':
        return Colors.greenAccent;
      case 'post-roll':
        return Colors.orangeAccent;
      default:
        return Colors.blueAccent;
    }
  }
}

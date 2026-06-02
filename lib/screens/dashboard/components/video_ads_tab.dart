import 'package:admin/screens/dashboard/components/constraints.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
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

  // Static Method to Load Video Ads
  static Future<void> loadVideoAds(
    StateSetter setState,
    BuildContext context,
    Function(bool) setIsLoading,
    Function(List<Map<String, dynamic>>) setVideoAds,
  ) async {
    setState(() {
      setIsLoading(true);
    });

    try {
      // Implement Logic to Load Video From Firebase

      final QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection(videoAdsCollection).get();
      List<Map<String, dynamic>> videoAds = querySnapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      setState(() {
        setVideoAds(videoAds);
        setIsLoading(false);
      });
    } catch (e) {
      print("Error loading video ads: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load video ads: $e')),
      );
      setState(() {
        setIsLoading(false);
      });
    }
  }
}

class _VideoAdsTabState extends State<VideoAdsTab> {
  String? _videoAdUrl;
  String _videoAdPlacement = '';
  double _videoAdStartTimestamp = 0; // Start time in seconds
  double _videoAdEndTimestamp = 10; // End time in seconds
  VideoPlayerController? _videoPlayerController;
  String? _selectedVideoToPlaceAdOnId; // ID of the Video to place the ad on
  double _videoDuration = 10; // Default duration

  //Video data for place ads
  List<Map<String, dynamic>> _availableVideos = [];
  bool _isLoadingAvailableVideos = true;

  // New variable for description
  String _adDescription = '';

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

  Future<void> _uploadVideoAd() async {
    if ((_videoAdUrl == null) ||
        _videoAdPlacement.isEmpty ||
        _selectedVideoToPlaceAdOnId == null ||
        _adDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select a video URL, enter placement details, Ad description and select a video to place the ad on.'),
        ),
      );
      return;
    }

    // Validate that the end timestamp is after the start timestamp
    if (_videoAdEndTimestamp <= _videoAdStartTimestamp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End timestamp must be greater than start timestamp.'),
        ),
      );
      return;
    }

    // Check for overlapping ads
    bool isOverlapping = await _checkIfAdOverlaps(_selectedVideoToPlaceAdOnId!,
        _videoAdStartTimestamp, _videoAdEndTimestamp);
    if (isOverlapping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad exists in this timeframe.'),
        ),
      );
      return; // Stop the upload
    }

    try {
      String videoUrl;

      videoUrl = _videoAdUrl!;

      // Ensure _selectedVideoToPlaceAdOnId is not null
      if (_selectedVideoToPlaceAdOnId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a video to place the ad on.')),
        );
        return;
      }

      final videoAdData = {
        'videoUrl': videoUrl,
        'placement': _videoAdPlacement,
        'description': _adDescription, // add Ad description
        'startTimestamp': _videoAdStartTimestamp, //Store as double
        'endTimestamp': _videoAdEndTimestamp, //Store as double
        'uploadTimestamp': FieldValue.serverTimestamp(),
      };

      // Add the ad data to a subcollection within the selected video document
      await FirebaseFirestore.instance
          .collection(videosCollection)
          .doc(_selectedVideoToPlaceAdOnId)
          .collection(videoAdsCollection)
          .add(videoAdData);

      setState(() {
        _videoAdUrl = null;
        _videoAdPlacement = '';
        _videoAdStartTimestamp = 0;
        _videoAdEndTimestamp = 10;
        _videoPlayerController?.dispose();
        _videoPlayerController = null;
        _selectedVideoToPlaceAdOnId = null;
        _adDescription = ''; // clear description
      });

      // Load Data After Upload
      await VideoAdsTab.loadVideoAds(
          setState,
          context,
          widget.onIsLoadingChanged,
          widget.onVideoAdsChanged); // reload Video ADs from Firebase

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video ad uploaded successfully!')),
      );
    } catch (e) {
      print("Error uploading video ad: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload video ad: $e')),
      );
    }
  }

  // Function to check if an ad overlaps with existing ads
  Future<bool> _checkIfAdOverlaps(
      String videoId, double startTimestamp, double endTimestamp) async {
    final QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance
            .collection(videosCollection)
            .doc(videoId)
            .collection(videoAdsCollection)
            .where('endTimestamp', isGreaterThan: startTimestamp)
            .where('startTimestamp', isLessThan: endTimestamp)
            .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _loadAvailableVideos() async {
    setState(() {
      _isLoadingAvailableVideos = true;
    });

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot querySnapshot =
          await firestore.collection(videosCollection).get();

      List<Map<String, dynamic>> videos = [];

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        // Change to QueryDocumentSnapshot
        var data = doc.data() as Map<String, dynamic>;
        String videoId = doc.id;
        String videoUrl = data['videoUrl'];
        double duration = 10; // Default value

        // Fetch video duration using _getVideoDuration
        try {
          duration = await _getVideoDuration(videoUrl);
        } catch (e) {
          print("Error fetching video duration: $e");
        }

        videos.add({
          'videoId': videoId,
          'title': data['title'],
          'description': data['description'],
          'videoUrl': videoUrl,
          'thumbnailUrl': data['thumbnailUrl'],
          'duration': duration, // Store the duration
        });
      }

      setState(() {
        _availableVideos = videos;
        _isLoadingAvailableVideos = false;
      });
    } catch (e) {
      print("Error fetching available videos: $e");
      setState(() {
        _isLoadingAvailableVideos = false;
      });
    }
  }

  Future<double> _getVideoDuration(String videoUrl) async {
    try {
      VideoPlayerController tempController =
          VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await tempController.initialize();
      double duration = tempController.value.duration.inSeconds.toDouble();
      await tempController.dispose(); // Dispose of the controller after use
      return duration;
    } catch (e) {
      print("Error getting video duration: $e");
      return 10; // Default value in case of error
    }
  }

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

          // Video URL Input

          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Video Ad URL',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: const Color(0xFF292929),
                    prefixIcon: const Icon(Icons.link, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _videoAdUrl = value;
                      _videoPlayerController?.dispose();
                      if (Uri.tryParse(value)?.hasAbsolutePath == true) {
                        _videoPlayerController =
                            VideoPlayerController.networkUrl(Uri.parse(value))
                              ..initialize().then((_) {
                                setState(() {
                                  _videoDuration = _videoPlayerController
                                          ?.value.duration.inSeconds
                                          .toDouble() ??
                                      10; // Get actual duration
                                  _videoAdEndTimestamp = _videoDuration;
                                });
                              });
                      } else {
                        _videoPlayerController = null;
                        _videoDuration = 10;
                        _videoAdEndTimestamp = _videoDuration;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Available Videos Dropdown
              Expanded(child: _buildAvailableVideosDropdown()),
            ],
          ),
          const SizedBox(height: 16),

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
                    prefixIcon:
                        const Icon(Icons.description, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() {
                    _adDescription = value;
                  }),
                ),
              ),
              const SizedBox(width: 16),

              // Placement Details
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Ad Placement Description',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: const Color(0xFF292929),
                    prefixIcon: const Icon(Icons.location_on,
                        color: Colors.white70), // Changed icon
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() {
                    _videoAdPlacement = value;
                  }),
                ),
              ),
            ],
          ),

          // Ad Description
          const SizedBox(height: 16),

          // Timestamp Input - Using RangeSlider
          _buildTimestampRangeSlider(),

          const SizedBox(height: 24),

          // Display Start and End Times
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start Time: ${_formatTimestamp(_videoAdStartTimestamp)}',
                    style: const TextStyle(color: Colors.white70)),
                Text('End Time: ${_formatTimestamp(_videoAdEndTimestamp)}',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),

          // Upload Button
          ElevatedButton(
            onPressed: _uploadVideoAd,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Upload Video Ad"),
          ),
          const SizedBox(height: 24),

          // Video Preview
          if (_videoPlayerController != null &&
              _videoPlayerController!.value.isInitialized)
            Column(
              children: [
                AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController!),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_videoPlayerController!.value.isPlaying) {
                        _videoPlayerController!.pause();
                      } else {
                        _videoPlayerController!.play();
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Icon(
                    _videoPlayerController!.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Existing Video Ads List
          Text(
            'Existing Video Ads',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.white) ??
                const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.isLoadingVideoAds
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : ListView.separated(
                    itemCount: widget.existingVideoAds.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: Colors.white30,
                    ),
                    itemBuilder: (context, index) {
                      final videoAd = widget.existingVideoAds[index];
                      return Card(
                        color: cardBackgroundColor,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            textColor: Colors.white,
                            title: Text(videoAd['placement'] ?? 'No Placement'),
                            subtitle: Text(
                                'Start: ${_formatTimestamp(videoAd['startTimestamp'])}, End: ${_formatTimestamp(videoAd['endTimestamp'])}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white70),
                                  onPressed: () {
                                    // Implement edit logic
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.white70),
                                  onPressed: () {
                                    // Implement delete logic
                                  },
                                ),
                              ],
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

  Widget _buildTimestampRangeSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.blue[700],
        inactiveTrackColor: Colors.grey[600],
        thumbColor: Colors.blueAccent,
        valueIndicatorColor: Colors.blueAccent,
        activeTickMarkColor: Colors.blue[700],
        inactiveTickMarkColor: Colors.grey[600],
        overlayColor: Colors.blue.withAlpha(32),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
        ),
      ),
      child: RangeSlider(
        min: 0.0,
        max: _videoDuration,
        values: RangeValues(_videoAdStartTimestamp, _videoAdEndTimestamp),
        divisions: 100, // Refine the increments
        labels: RangeLabels(
          _formatTimestamp(_videoAdStartTimestamp),
          _formatTimestamp(_videoAdEndTimestamp),
        ),
        onChanged: (RangeValues values) {
          setState(() {
            _videoAdStartTimestamp = values.start;
            _videoAdEndTimestamp = values.end;
          });
        },
      ),
    );
  }

  Widget _buildAvailableVideosDropdown() {
    return _isLoadingAvailableVideos
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : DropdownButtonFormField<String>(
            value: _selectedVideoToPlaceAdOnId,
            decoration: InputDecoration(
              labelText: 'Video to Place Ad On',
              labelStyle: const TextStyle(color: Colors.white70),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: const Color(0xFF292929),
              prefixIcon:
                  const Icon(Icons.video_library, color: Colors.white70),
            ),
            dropdownColor: const Color(0xFF292929),
            style: const TextStyle(color: Colors.white),
            hint: const Text('Select a Video',
                style: TextStyle(color: Colors.white70)),
            items: _availableVideos.map((video) {
              return DropdownMenuItem<String>(
                value: video['videoId'],
                child: Text(video['title'] ?? 'Unknown Video'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedVideoToPlaceAdOnId = value;
                // Update video duration based on the selected video
                final selectedVideo = _availableVideos
                    .firstWhere((video) => video['videoId'] == value);
                _videoDuration = selectedVideo['duration'];
                _videoAdEndTimestamp =
                    _videoDuration; // Set default end time to video duration
                _videoAdStartTimestamp = 0; //Reset start time

                // _loadVideoAds(); // Load Video Ads From The Collection - TO BE MOVED IN advertisement_page
              });
            },
          );
  }

  String _formatTimestamp(double timestamp) {
    Duration duration = Duration(microseconds: (timestamp * 1000000).round());
    return "${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}.${duration.inMilliseconds.remainder(1000).toString().padRight(3, '0')}";
  }
}

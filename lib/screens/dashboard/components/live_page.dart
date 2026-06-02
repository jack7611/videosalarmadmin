import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart' as web_file_picker;

class LiveVideosPage extends StatefulWidget {
  const LiveVideosPage({Key? key}) : super(key: key);

  @override
  State<LiveVideosPage> createState() => _LiveVideosPageState();
}

class _LiveVideosPageState extends State<LiveVideosPage> with TickerProviderStateMixin {
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _videoTitleController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode(debugLabel: 'urlField');
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _showVideoDetails = false.obs;
  final _videoThumbnailUrl = ''.obs;
  final _isLoading = false.obs;
  final _videoDescription = ''.obs;
  final _videoTags = <String>[].obs;
  final _videoId = ''.obs;
  final _actualStartTime = 'Not Available'.obs;
  final _concurrentViewers = 0.obs;
  final _pickedThumbnail = Rx<Uint8List?>(null);

  final String _apiKey = 'AIzaSyA3Co3oJkuMfsrLttokAU55y4STgBcZNHw';
  final _debounceController = GetxDebounceController();
  final _pastLiveVideos = <DocumentSnapshot>[].obs;
  final _isLoadingPastVideos = false.obs;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _debounceController.debouncedFetch.listen((_) {
      _fetchVideoDetails();
    });
    _loadPastLiveVideos();
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _videoUrlController.dispose();
    _videoTitleController.dispose();
    _urlFocusNode.dispose();
    _debounceController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String? _extractVideoId(String url) {
    Uri uri = Uri.parse(url);
    if (uri.host == 'www.youtube.com' || uri.host == 'youtube.com') {
      if (uri.path == '/live/') {
        return uri.pathSegments.last;
      } else if (uri.path == '/watch') {
        return uri.queryParameters['v'];
      } else {
        List<String> pathSegments = uri.pathSegments;
        if (pathSegments.length > 1 && pathSegments[0] == "live") {
          return pathSegments[1];
        }
        RegExp regExp = RegExp(r'.*youtube\.com.*(?:\/|v=)([^&]+)');
        Match? match = regExp.firstMatch(url);

        if (match != null && match.groupCount >= 1) {
          return match.group(1);
        }
      }
    } else if (uri.host == 'youtu.be') {
      return uri.pathSegments.first;
    }
    return null;
  }

  Future<void> _fetchVideoDetails() async {
    _isLoading.value = true;
    _showVideoDetails.value = false;
    _videoThumbnailUrl.value = '';
    _videoDescription.value = '';
    _videoTags.clear();
    _actualStartTime.value = 'Not Available';
    _videoTitleController.text = '';
    _concurrentViewers.value = 0;
    _pickedThumbnail.value = null;

    final videoUrl = _videoUrlController.text;
    final videoId = _extractVideoId(videoUrl);

    if (videoId == null) {
      _isLoading.value = false;
      _showVideoDetails.value = false;
      _videoThumbnailUrl.value = 'https://via.placeholder.com/480x270?text=Invalid+URL';
      _videoDescription.value = 'Invalid YouTube URL. Please enter a valid URL.';
      return;
    }

    _videoId.value = videoId;
    final apiUrl = 'https://www.googleapis.com/youtube/v3/videos?part=snippet,liveStreamingDetails&id=$videoId&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] != null && data['items'].isNotEmpty) {
          final video = data['items'][0];

          _showVideoDetails.value = true;
          _videoTitleController.text = video['snippet']['title'] ?? 'No Title';
          _videoThumbnailUrl.value = video['snippet']['thumbnails']['high']['url'] ??
              video['snippet']['thumbnails']['medium']['url'] ??
              'https://via.placeholder.com/480x270?text=Thumbnail+Not+Available';

          _videoDescription.value = (video['snippet']['description'] as String)
                  .split(' ')
                  .take(50)
                  .join(' ') + '...';

          _videoTags.assignAll(
              List<String>.from(video['snippet']['tags']?.take(6) ?? []));

          if (video['liveStreamingDetails'] != null) {
            _actualStartTime.value = video['liveStreamingDetails']['actualStartTime'] ?? 'Not Available';
            _concurrentViewers.value = int.tryParse(
                    video['liveStreamingDetails']['concurrentViewers'] ?? '0') ?? 0;
          } else {
            _actualStartTime.value = 'Not a live stream or start time not available';
            _concurrentViewers.value = 0;
          }
          _isLoading.value = false;
        } else {
          _isLoading.value = false;
          _showVideoDetails.value = false;
          _videoThumbnailUrl.value = 'https://via.placeholder.com/480x270?text=Video+Not+Found';
          _videoDescription.value = 'Video details not found for this URL.';
        }
      } else {
        _isLoading.value = false;
        _showVideoDetails.value = false;
        _videoThumbnailUrl.value = 'https://via.placeholder.com/480x270?text=API+Error';
        _videoDescription.value = 'Error fetching video details from YouTube API: ${response.statusCode}';
      }
    } catch (e) {
      _isLoading.value = false;
      _showVideoDetails.value = false;
      _videoThumbnailUrl.value = 'https://via.placeholder.com/480x270?text=Exception';
      _videoDescription.value = 'An error occurred: $e';
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      web_file_picker.FilePickerResult? result =
          await web_file_picker.FilePicker.platform.pickFiles(
        type: web_file_picker.FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        _pickedThumbnail.value = result.files.first.bytes;
      }
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        _pickedThumbnail.value = await image.readAsBytes();
      }
    }
  }

  void _resetVideoDetails() {
    _videoUrlController.clear();
    _videoTitleController.clear();
    _showVideoDetails.value = false;
    _videoThumbnailUrl.value = '';
    _videoDescription.value = '';
    _videoTags.clear();
    _actualStartTime.value = 'Not Available';
    _concurrentViewers.value = 0;
    _pickedThumbnail.value = null;
  }

  Future<void> _submitVideoDetails() async {
    final String videoId = _videoId.value;
    final String videoTitle = _videoTitleController.text;
    final String videoDescription = _videoDescription.value;
    final List<String> videoTags = _videoTags.toList();
    String videoThumbnailUrl = _videoThumbnailUrl.value;
    final String actualStartTime = _actualStartTime.value;
    final int concurrentViewers = _concurrentViewers.value;

    if (_pickedThumbnail.value != null) {
      videoThumbnailUrl = "url_to_uploaded_image";
    }

    try {
      await FirebaseFirestore.instance.collection('live_videos').doc(videoId).set({
        'videoId': videoId,
        'videoTitle': videoTitle,
        'videoDescription': videoDescription,
        'videoTags': videoTags,
        'videoThumbnailUrl': videoThumbnailUrl,
        'actualStartTime': actualStartTime,
        'concurrentViewers': concurrentViewers,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.dialog(
        AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Success', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Video details saved successfully!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK'),
              onPressed: () {
                Get.back();
                _loadPastLiveVideos();
                _resetVideoDetails();
              },
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      Get.dialog(
        AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Error', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Failed to save video details: $e',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK'),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadPastLiveVideos() async {
    _isLoadingPastVideos.value = true;

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('live_videos')
          .orderBy('createdAt', descending: true)
          .limit(12)
          .get();

      _pastLiveVideos.assignAll(snapshot.docs);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load past live videos: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      _isLoadingPastVideos.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 40),
                        _buildUrlInputSection(),
                        const SizedBox(height: 32),
                        _buildVideoDetailsSection(),
                        const SizedBox(height: 56),
                        _buildPastVideosSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.live_tv_rounded,
              size: 32,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Video Management',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 32,
                    ) ??
                    const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage and organize your live streaming content',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInputSection() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Enter YouTube Live URL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              focusNode: _urlFocusNode,
              controller: _videoUrlController,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.link, color: Colors.blue, size: 20),
                ),
                suffixIcon: Obx(() => _isLoading.value
                    ? Container(
                        margin: const EdgeInsets.all(12),
                        child: const CircularProgressIndicator(
                          color: Colors.blue,
                          strokeWidth: 2,
                        ),
                      )
                    : IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.search, color: Colors.white, size: 20),
                        ),
                        onPressed: () {
                          FocusScope.of(context).requestFocus(_urlFocusNode);
                          _debounceController.fetchData();
                        },
                      )),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_urlFocusNode);
                _debounceController.fetchData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDetailsSection() {
    return Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _showVideoDetails.value
            ? Container(
                key: const ValueKey<bool>(true),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildThumbnailSection(),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 3,
                          child: _buildVideoInfoSection(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                  ],
                ),
              )
            : const SizedBox(key: ValueKey<bool>(false)),
      ),
    );
  }

  Widget _buildThumbnailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thumbnail',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Obx(() {
                if (_pickedThumbnail.value != null) {
                  return Image.memory(
                    _pickedThumbnail.value!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  );
                } else {
                  return Image.network(
                    _videoThumbnailUrl.value,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, exception, stackTrace) {
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              }),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _videoTitleController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Video Title',
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 20),
        
        if (_videoTags.isNotEmpty) ...[
          Text(
            'Tags',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _videoTags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.5)),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),
        ],

        _buildInfoCard('Description', _videoDescription.value),
        const SizedBox(height: 16),
        _buildInfoCard('Start Time', _actualStartTime.value),
        const SizedBox(height: 16),
        _buildInfoCard('Concurrent Viewers', _concurrentViewers.value.toString()),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _submitVideoDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.save, size: 20),
            SizedBox(width: 8),
            Text(
              'Save Video Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastVideosSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.1),
                Colors.red.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Past Live Videos',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 28,
                    ) ??
                    const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Obx(() {
          if (_isLoadingPastVideos.value) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          } else if (_pastLiveVideos.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No past live videos found',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your uploaded videos will appear here',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                ),
                itemCount: _pastLiveVideos.length,
                itemBuilder: (context, index) {
                  final video = _pastLiveVideos[index];
                  return EnhancedVideoCard(video: video);
                },
              ),
            );
          }
        }),
      ],
    );
  }
}

class EnhancedVideoCard extends StatefulWidget {
  const EnhancedVideoCard({Key? key, required this.video}) : super(key: key);

  final DocumentSnapshot video;

  @override
  State<EnhancedVideoCard> createState() => _EnhancedVideoCardState();
}

class _EnhancedVideoCardState extends State<EnhancedVideoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoData = widget.video.data() as Map<String, dynamic>?;
    final videoTitle = videoData?['videoTitle'] as String? ?? 'No Title';
    final videoThumbnailUrl = videoData?['videoThumbnailUrl'] as String? ??
        'https://via.placeholder.com/400x225?text=No+Thumbnail';
    final concurrentViewers = videoData?['concurrentViewers'] as int? ?? 0;
    final videoTags = List<String>.from(videoData?['videoTags'] ?? []);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isHovered 
                      ? Colors.blue.withOpacity(0.5) 
                      : Colors.grey.withOpacity(0.2),
                  width: _isHovered ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            videoThumbnailUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, exception, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey.withOpacity(0.3),
                                      Colors.grey.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.grey.withOpacity(0.7),
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Image not available',
                                      style: TextStyle(
                                        color: Colors.grey.withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 8,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isHovered)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            videoTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                color: Colors.grey.withOpacity(0.7),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${concurrentViewers.toString()} viewers',
                                style: TextStyle(
                                  color: Colors.grey.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          if (videoTags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: videoTags.take(2).map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Keep the original PastLiveVideoCard for backward compatibility
class PastLiveVideoCard extends StatelessWidget {
  const PastLiveVideoCard({Key? key, required this.video}) : super(key: key);

  final DocumentSnapshot video;

  @override
  Widget build(BuildContext context) {
    final videoData = video.data() as Map<String, dynamic>?;
    final videoTitle = videoData?['videoTitle'] as String? ?? 'No Title';
    final videoThumbnailUrl = videoData?['videoThumbnailUrl'] as String? ??
        'https://via.placeholder.com/220x120?text=No+Thumbnail';
    final concurrentViewers = videoData?['concurrentViewers'] as int? ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.network(
              videoThumbnailUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  color: Colors.grey.withOpacity(0.3),
                  child: const Center(
                    child: Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  videoTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Viewers: $concurrentViewers',
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.7),
                    fontSize: 12,
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

class GetxDebounceController extends GetxController {
  final debouncedFetch = Rx<void>(null);

  void fetchData() {
    Future.delayed(const Duration(milliseconds: 500), () {
      debouncedFetch.value = null;
    });
  }
}
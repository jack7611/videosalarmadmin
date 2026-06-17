import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class WebsiteVideosPage extends StatefulWidget {
  const WebsiteVideosPage({Key? key}) : super(key: key);

  @override
  State<WebsiteVideosPage> createState() => _WebsiteVideosPageState();
}

class _WebsiteVideosPageState extends State<WebsiteVideosPage> {
  final _titleController = TextEditingController();
  Uint8List? _pickedImageBytes;
  String? _pickedFileName;

  bool _uploading = false;
  String? _uploadError;
  double _uploadProgress = 0;

  List<Map<String, dynamic>> _videos = [];
  bool _loadingList = true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() => _loadingList = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('website_videos')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() {
        _videos = snap.docs.map((d) {
          final data = Map<String, dynamic>.from(d.data());
          data['id'] = d.id;
          return data;
        }).toList();
        _loadingList = false;
      });
    } catch (e) {
      setState(() => _loadingList = false);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedImageBytes = result.files.first.bytes;
        _pickedFileName = result.files.first.name;
      });
    }
  }

  Future<void> _upload() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _uploadError = 'Please enter a title.');
      return;
    }
    if (_pickedImageBytes == null) {
      setState(() => _uploadError = 'Please select a thumbnail image.');
      return;
    }

    setState(() {
      _uploading = true;
      _uploadError = null;
      _uploadProgress = 0;
    });

    try {
      final fileName =
          'website_videos/${DateTime.now().millisecondsSinceEpoch}_${_pickedFileName ?? "thumb.jpg"}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putData(
        _pickedImageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          setState(() {
            _uploadProgress =
                snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('website_videos').add({
        'title': title,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      setState(() {
        _pickedImageBytes = null;
        _pickedFileName = null;
        _uploading = false;
        _uploadProgress = 0;
      });

      Get.snackbar(
        'Added',
        '"$title" is now live on the website.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      _fetchVideos();
    } catch (e) {
      setState(() {
        _uploadError = e.toString();
        _uploading = false;
      });
    }
  }

  Future<void> _delete(String docId, String imageUrl, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Video Card',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Remove "$title" from the website?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('website_videos')
          .doc(docId)
          .delete();
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (_) {}
      Get.snackbar('Deleted', '"$title" removed from the website.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      _fetchVideos();
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    return DateFormat('dd MMM yyyy').format(ts.toDate().toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Website Videos',
          style: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _fetchVideos,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 24),
            _buildAddForm(),
            const SizedBox(height: 32),
            _buildVideoList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Videos added here appear on videosalarm.com homepage. '
              'Add title + thumbnail image — they show instantly on the website.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_circle_outline_rounded,
                  color: Color(0xFF6366F1), size: 22),
            ),
            const SizedBox(width: 14),
            const Text(
              'Add New Video Card',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          ]),
          const SizedBox(height: 20),

          // Title field
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            maxLength: 80,
            decoration: InputDecoration(
              counterStyle: const TextStyle(color: Colors.white38),
              labelText: 'Video / Movie Title',
              labelStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.movie_creation_rounded,
                  color: Color(0xFF6366F1), size: 20),
              filled: true,
              fillColor: const Color(0xFF0F0F0F),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF6366F1), width: 2)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
          ),
          const SizedBox(height: 16),

          // Image picker
          GestureDetector(
            onTap: _uploading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pickedImageBytes != null
                      ? const Color(0xFF6366F1)
                      : Colors.white12,
                  width: _pickedImageBytes != null ? 2 : 1,
                ),
              ),
              child: _pickedImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_pickedImageBytes!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _pickedImageBytes = null;
                                _pickedFileName = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            color: Colors.white38, size: 40),
                        const SizedBox(height: 8),
                        const Text('Click to select thumbnail image',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('JPG, PNG, WEBP',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 12)),
                      ],
                    ),
            ),
          ),

          if (_uploadError != null) ...[
            const SizedBox(height: 12),
            Text(_uploadError!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],

          if (_uploading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              backgroundColor: Colors.white10,
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text(
              _uploadProgress > 0
                  ? 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                  : 'Preparing...',
              style:
                  const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              ),
              onPressed: _uploading ? null : _upload,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.cloud_upload_rounded, size: 20),
              label: Text(
                _uploading ? 'Uploading...' : 'Add to Website',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.video_library_rounded,
                    color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 14),
              const Text(
                'Live on Website',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (!_loadingList)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    '${_videos.length} video${_videos.length == 1 ? '' : 's'}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
            ]),
          ),
          if (_loadingList)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF6366F1))),
            )
          else if (_videos.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Text(
                'No videos added yet. Add your first video card above.',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            )
          else
            ...List.generate(_videos.length, (i) {
              final v = _videos[i];
              final title = v['title'] as String? ?? '';
              final imageUrl = v['imageUrl'] as String? ?? '';
              final ts = v['createdAt'] as Timestamp?;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: i.isOdd
                      ? Colors.white.withOpacity(0.02)
                      : Colors.transparent,
                  border: const Border(
                      top: BorderSide(color: Colors.white10, width: 0.5)),
                ),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl,
                            width: 80,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 50,
                              color: Colors.white10,
                              child: const Icon(Icons.broken_image_rounded,
                                  color: Colors.white38, size: 20),
                            ))
                        : Container(
                            width: 80,
                            height: 50,
                            color: Colors.white10,
                            child: const Icon(Icons.image_rounded,
                                color: Colors.white38, size: 20),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        if (ts != null)
                          Text(_formatDate(ts),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _delete(v['id'], imageUrl, title),
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 22),
                    tooltip: 'Remove from website',
                  ),
                ]),
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}

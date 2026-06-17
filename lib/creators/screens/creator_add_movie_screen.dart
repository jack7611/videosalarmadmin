import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:admin/controllers/movie_controller.dart';
import 'package:admin/creators/controllers/creator_movie_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:dotted_border/dotted_border.dart';

class CreatorAddMovieScreen extends StatefulWidget {
  const CreatorAddMovieScreen({Key? key}) : super(key: key);

  @override
  State<CreatorAddMovieScreen> createState() => _CreatorAddMovieScreenState();
}

class _CreatorAddMovieScreenState extends State<CreatorAddMovieScreen> {
  final _formKey = GlobalKey<FormState>();
  late final MovieController _movieController;

  // EN / HI controllers
  final titleEn = TextEditingController();
  final titleHi = TextEditingController();
  final descEn = TextEditingController();
  final descHi = TextEditingController();
  final durationEn = TextEditingController();
  final durationHi = TextEditingController();
  final releaseYearEn = TextEditingController();
  final releaseYearHi = TextEditingController();
  String? categoryEn;
  String? categoryHi;
  String? cbfcEn;
  String? cbfcHi;
  final directorEn = TextEditingController();
  final directorHi = TextEditingController();
  final starcastEn = TextEditingController();
  final starcastHi = TextEditingController();

  Timestamp? releaseDate;
  final releaseDateController = TextEditingController();
  final videoUrl2 = TextEditingController();
  final thumbnailUrl = TextEditingController();

  bool _active = true;
  bool _loading = false;
  File? _thumbnailFile;
  Uint8List? _thumbnailBytes;
  double _uploadProgress = 0.0;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _movieController = Get.put(MovieController());
  }

  @override
  void dispose() {
    titleEn.dispose();
    titleHi.dispose();
    descEn.dispose();
    descHi.dispose();
    durationEn.dispose();
    durationHi.dispose();
    releaseYearEn.dispose();
    releaseYearHi.dispose();
    directorEn.dispose();
    directorHi.dispose();
    starcastEn.dispose();
    starcastHi.dispose();
    releaseDateController.dispose();
    videoUrl2.dispose();
    thumbnailUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Movie',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard(
                    title: 'Movie Details',
                    icon: Icons.movie_creation_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dualField('Title', titleEn, titleHi),
                        _dualField('Description', descEn, descHi),
                        _dualField('Duration', durationEn, durationHi),
                        const SizedBox(height: 4),
                        const Text(
                          'Ex: 1h 42m  |  1 घंटे 42 मिनट',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        _dualField('Release Year', releaseYearEn, releaseYearHi),
                      ],
                    ),
                  ),
                  _buildCard(
                    title: 'Category & CBFC',
                    icon: Icons.category_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dualDropdown(
                          label: 'Category',
                          enValue: categoryEn,
                          hiValue: categoryHi,
                          enOptions: ['Movie', 'Song'],
                          hiOptions: ['फ़िल्म', 'गाना'],
                          onEnChanged: (v) => setState(() => categoryEn = v),
                          onHiChanged: (v) => setState(() => categoryHi = v),
                        ),
                        _dualDropdown(
                          label: 'CBFC Rating',
                          enValue: cbfcEn,
                          hiValue: cbfcHi,
                          enOptions: ['U', 'U/A 13+', 'U/A 16+', 'A'],
                          hiOptions: ['यू', 'यू/ए 13+', 'यू/ए 16+', 'ए'],
                          onEnChanged: (v) => setState(() => cbfcEn = v),
                          onHiChanged: (v) => setState(() => cbfcHi = v),
                        ),
                      ],
                    ),
                  ),
                  _buildCard(
                    title: 'Crew',
                    icon: Icons.people_rounded,
                    child: Column(
                      children: [
                        _dualField('Director', directorEn, directorHi),
                        _dualField('Starcast', starcastEn, starcastHi),
                      ],
                    ),
                  ),
                  _buildCard(
                    title: 'Media',
                    icon: Icons.perm_media_rounded,
                    child: Column(
                      children: [
                        _labeledField('Video URL (Bunny/CDN)', videoUrl2),
                        const SizedBox(height: 16),
                        _buildReleaseDatePicker(),
                        const SizedBox(height: 16),
                        _buildThumbnailPicker(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSubmitButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Card wrapper ─────────────────────────────────────────────────────────

  Widget _buildCard(
      {required String title,
      required IconData icon,
      required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF6366F1), size: 18),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Input field ───────────────────────────────────────────────────────────

  Widget _inputField(String hint, TextEditingController c,
      {bool required = true}) {
    return TextFormField(
      controller: c,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }

  Widget _labeledField(String label, TextEditingController c,
      {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _inputField(label, c, required: required),
      ],
    );
  }

  // ── Dual field (EN + HI) ──────────────────────────────────────────────────

  Widget _dualField(
      String label, TextEditingController en, TextEditingController hi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(label,
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: _inputField('English (EN)', en)),
          const SizedBox(width: 12),
          Expanded(child: _inputField('Hindi (HI)', hi)),
        ]),
      ],
    );
  }

  // ── Dual dropdown ─────────────────────────────────────────────────────────

  Widget _dualDropdown({
    required String label,
    required String? enValue,
    required String? hiValue,
    required List<String> enOptions,
    required List<String> hiOptions,
    required ValueChanged<String?> onEnChanged,
    required ValueChanged<String?> onHiChanged,
  }) {
    InputDecoration _dropDeco() => InputDecoration(
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF6366F1)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(label,
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: enValue,
              items: enOptions
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14))))
                  .toList(),
              decoration: _dropDeco(),
              dropdownColor: const Color(0xFF2A2A2A),
              hint: const Text('EN',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
              onChanged: onEnChanged,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: hiValue,
              items: hiOptions
                  .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14))))
                  .toList(),
              decoration: _dropDeco(),
              dropdownColor: const Color(0xFF2A2A2A),
              hint: const Text('HI',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
              onChanged: onHiChanged,
            ),
          ),
        ]),
      ],
    );
  }

  // ── Release date picker ───────────────────────────────────────────────────

  Widget _buildReleaseDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Release Date',
            style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final currentVal = releaseDate?.toDate() ?? now;
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: currentVal,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(currentVal),
              );
              if (pickedTime != null) {
                final dt = DateTime(pickedDate.year, pickedDate.month,
                    pickedDate.day, pickedTime.hour, pickedTime.minute);
                setState(() {
                  releaseDate = Timestamp.fromDate(dt);
                  releaseDateController.text =
                      DateFormat('yyyy-MM-dd HH:mm').format(dt);
                });
              }
            }
          },
          child: AbsorbPointer(
            child: _inputField('Tap to select date', releaseDateController,
                required: false),
          ),
        ),
      ],
    );
  }

  // ── Thumbnail picker ──────────────────────────────────────────────────────

  Widget _buildThumbnailPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thumbnail Image',
            style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickThumbnail,
          child: DottedBorder(
            color: Colors.white24,
            borderType: BorderType.RRect,
            radius: const Radius.circular(10),
            dashPattern: const [6, 4],
            child: Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
                image: kIsWeb
                    ? (_thumbnailBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_thumbnailBytes!),
                            fit: BoxFit.cover)
                        : (thumbnailUrl.text.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(thumbnailUrl.text),
                                fit: BoxFit.cover)
                            : null))
                    : (_thumbnailFile != null
                        ? DecorationImage(
                            image: FileImage(_thumbnailFile!),
                            fit: BoxFit.cover)
                        : null),
              ),
              child: (_thumbnailFile == null &&
                      _thumbnailBytes == null &&
                      thumbnailUrl.text.isEmpty)
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.cloud_upload_outlined,
                            color: Colors.white38, size: 44),
                        SizedBox(height: 10),
                        Text('Tap to upload thumbnail',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 13)),
                        SizedBox(height: 4),
                        Text('JPG, PNG, WEBP supported',
                            style: TextStyle(
                                color: Colors.white24, fontSize: 11)),
                      ],
                    )
                  : null,
            ),
          ),
        ),
        if (_uploadingImage) ...[
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.white12,
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
              'Uploading thumbnail: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
              style:
                  const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ],
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_loading || _uploadingImage) ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          disabledBackgroundColor: Colors.white12,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Upload Movie',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
      ),
    );
  }

  // ── File pick & upload ────────────────────────────────────────────────────

  Future<void> _pickThumbnail() async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final ext = file.extension?.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
      Get.snackbar('Invalid Format',
          'Please select a jpg, jpeg, png, webp, or gif image',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() {
      if (kIsWeb) {
        _thumbnailBytes = file.bytes;
        _thumbnailFile = null;
      } else {
        _thumbnailFile = File(file.path!);
        _thumbnailBytes = null;
      }
      thumbnailUrl.clear();
    });
  }

  Future<String?> _uploadThumbnail() async {
    try {
      setState(() {
        _uploadingImage = true;
        _uploadProgress = 0;
      });
      final fileName =
          'movie_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('movies_thumbnail')
          .child(fileName);

      final UploadTask task = kIsWeb
          ? ref.putData(_thumbnailBytes!)
          : ref.putFile(_thumbnailFile!);

      task.snapshotEvents.listen((e) => setState(
          () => _uploadProgress = e.bytesTransferred / e.totalBytes));

      final snapshot = await task;
      final url = await snapshot.ref.getDownloadURL();
      thumbnailUrl.text = url;
      return url;
    } catch (e) {
      Get.snackbar('Upload Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return null;
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final creatorId =
        html.window.localStorage['creatorId'] ?? '';

    if (creatorId.isEmpty) {
      Get.snackbar('Error', 'Creator session expired. Please log in again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      setState(() => _loading = false);
      return;
    }

    String? finalThumbnailUrl = thumbnailUrl.text;
    if (_thumbnailFile != null || _thumbnailBytes != null) {
      final url = await _uploadThumbnail();
      if (url == null) {
        setState(() => _loading = false);
        return;
      }
      finalThumbnailUrl = url;
    }

    final payload = {
      'title': {'en': titleEn.text.trim(), 'hi': titleHi.text.trim()},
      'description': {
        'en': descEn.text.trim(),
        'hi': descHi.text.trim()
      },
      'duration': {
        'en': durationEn.text.trim(),
        'hi': durationHi.text.trim()
      },
      'releaseYear': {
        'en': releaseYearEn.text.trim(),
        'hi': releaseYearHi.text.trim()
      },
      'category': {'en': categoryEn, 'hi': categoryHi},
      'cbfc': {'en': cbfcEn, 'hi': cbfcHi},
      'director': {
        'en': directorEn.text.trim(),
        'hi': directorHi.text.trim()
      },
      'starcast': {
        'en': starcastEn.text.trim(),
        'hi': starcastHi.text.trim()
      },
      'createdAt': FieldValue.serverTimestamp(),
      'releaseDate':
          releaseDate ?? FieldValue.serverTimestamp(),
      'views': 0,
      'watchSeconds': 0,
      'videoUrl': '',
      'videoUrl2': videoUrl2.text.trim(),
      'creatorId': creatorId,
      'thumbnailUrl': finalThumbnailUrl ?? '',
      'active': _active,
    };

    try {
      await _movieController.createMovie(payload);

      if (Get.isRegistered<CreatorMovieController>()) {
        Get.find<CreatorMovieController>().fetchCreatorMovies();
      }

      Get.snackbar('Success', 'Movie uploaded successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

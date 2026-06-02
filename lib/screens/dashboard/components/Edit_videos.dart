import 'package:admin/controllers/Videos_controller.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:html' as html;

class EditVideoPage extends StatefulWidget {
  final String videoId; // Video ID to edit

  const EditVideoPage({Key? key, required this.videoId}) : super(key: key);

  @override
  _EditVideoPageState createState() => _EditVideoPageState();
}

class _EditVideoPageState extends State<EditVideoPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController authorController = TextEditingController();
  html.File? _imageFile; // Selected image file
  String imageUrl = '';
  String videoUrl = '';
  bool isSubmitting = false; // For showing the progress indicator
  final VideosController _controller = Get.find<VideosController>();

  @override
  void initState() {
    super.initState();
    _fetchVideoData();
  }

  Future<void> _fetchVideoData() async {
    var video = _controller.videos.firstWhere((video) => video.videoUrl == widget.videoId);
    titleController.text = video.title;
    descriptionController.text = video.description;
    authorController.text = video.category;
    imageUrl = video.thumbnailUrl;
    videoUrl = video.videoUrl;
    setState(() {});
  }

  void _pickThumbnail() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      setState(() {
        _imageFile = files[0]; // Store the selected image file
      });

      final reader = html.FileReader();
      reader.readAsDataUrl(files[0]);

      reader.onLoadEnd.listen((e) {
        setState(() {
          imageUrl = reader.result as String;
        });
      });
    });
  }

  Future<String> _uploadFileToStorage(html.File file, String folder) async {
    try {
      final firebase_storage.Reference storageRef = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('$folder/${file.name}');
      final uploadTask = storageRef.putBlob(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Failed to upload file: $e");
      throw Exception("Failed to upload file: $e");
    }
  }

  Future<void> _saveEditedVideo() async {
    setState(() {
      isSubmitting = true; // Show progress indicator
    });

    try {
      String newImageUrl = imageUrl;
      if (_imageFile != null) {
        newImageUrl = await _uploadFileToStorage(_imageFile!, 'images');
      }

      // Only update the changed fields
      await _controller.updateVideo(
        widget.videoId,
        titleController.text,
        descriptionController.text,
        authorController.text,
        newImageUrl,
        videoUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video updated successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      Get.back(); // Navigate back after success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update video. Please try again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false; // Hide progress indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Video"),
        backgroundColor: const Color.fromARGB(255, 19, 24, 27),
        elevation: 4.0,
        shadowColor: Colors.black54,
      ),
      body: Row(
        children: [
          // Side menu

          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 30, 30, 30),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: const Text(
                          "Edit Video",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildImageSection(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormSection("Author", authorController, "Enter the author's name"),
                                const SizedBox(height: 16),
                                _buildFormSection("Title", titleController, "Enter the title of the video"),
                                const SizedBox(height: 16),
                                _buildFormSection("Description", descriptionController, "Enter a brief description", maxLines: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        imageUrl.isEmpty
            ? Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  image: const DecorationImage(
                    image: AssetImage('assets/placeholder.png'),
                    fit: BoxFit.contain,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No Image Selected',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : Image.network(imageUrl, height: 300, fit: BoxFit.contain),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _pickThumbnail,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 37, 35, 35),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Change Thumbnail"),
        ),
      ],
    );
  }

  Widget _buildFormSection(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color.fromARGB(255, 40, 40, 40),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return isSubmitting
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _saveEditedVideo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 37, 35, 35),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Submit Changes"),
          );
  }
}

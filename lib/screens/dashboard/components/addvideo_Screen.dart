import 'dart:async';
import 'dart:html' as html;
import 'package:admin/controllers/Videos_controller.dart';
import 'package:admin/screens/dashboard/components/Videos_page.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

// Import necessary libraries for HTTP requests and JSON encoding
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddVideoPage extends StatefulWidget {
  const AddVideoPage({Key? key}) : super(key: key);

  @override
  _AddVideoPageState createState() => _AddVideoPageState();
}

class _AddVideoPageState extends State<AddVideoPage> {
  TextEditingController categoryController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController videoUrlController = TextEditingController();
  TextEditingController directorController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController releaseYearController = TextEditingController();
  TextEditingController starcastController = TextEditingController();
  String? _cbfcValue;
  html.File? _imageFile;
  html.File? _videoFile;
  String _imageUrl = '';
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isVideoLoaded = false;
  bool isUploading = false;
  bool _useUrl = false;
  final VideosController videosController = Get.find();

  final List<String> cbfcOptions = [
    "U",
    "UA",
    "U/A 13+",
    "U/A 16+",
    "A",
  ];

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _pickImageWeb() async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      setState(() {
        _imageFile = files[0];
      });

      final reader = html.FileReader();
      reader.readAsDataUrl(files[0]);

      reader.onLoadEnd.listen((e) {
        setState(() {
          _imageUrl = reader.result as String;
        });
      });
    });
  }

  void _pickVideoWeb() async {
    setState(() {
      _useUrl = false;
    });
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'video/*';
    uploadInput.multiple = false;
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;

      if (files == null || files.isEmpty) {
        print('No video selected');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No video selected')));
        return;
      }

      setState(() {
        _videoFile = files[0];
        _isVideoLoaded = false;
        _initializeVideoPlayerFromFile();
      });
    });
  }

  void _initializeVideoPlayerFromFile() {
    if (_videoFile == null) return;

    final videoUrl = html.Url.createObjectUrlFromBlob(_videoFile!);
    _videoPlayerController = VideoPlayerController.network(videoUrl);

    _initializeChewieController();
  }

  void _initializeChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: true,
      aspectRatio: 16 / 9,
      placeholder: const Center(
        child: CircularProgressIndicator(color: Colors.grey),
      ),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            'Error loading video: $errorMessage',
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );

    _videoPlayerController.initialize().then((_) {
      setState(() {
        _isVideoLoaded = true;
      });
    });
  }

  Future<String> _uploadFileToStorage(html.File file, String folder) async {
    try {
      final firebase_storage.Reference storageRef = firebase_storage
          .FirebaseStorage.instance
          .ref()
          .child('$folder/${file.name}');

      final uploadTask = storageRef.putBlob(file);

      final snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print("Failed to upload file: $e");
      throw Exception("Failed to upload file: $e");
    }
  }

  // Function to send a notification about a new video
  Future<void> sendNewVideoNotification(String videoTitle) async {
    final url = Uri.parse(""); // Replace with your server URL

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': videoTitle}),
    );

    if (response.statusCode == 200) {
      print("✅ Notification sent!");
    } else {
      print("❌ Notification failed: ${response.body}");
    }
  }

  Future<void> _submitVideo() async {
    setState(() {
      isUploading = true;
    });

    String title = titleController.text.trim();
    String description = descriptionController.text.trim();
    String category = categoryController.text.trim();
    String videoUrlFromForm = videoUrlController.text.trim();
    String? cbfc = _cbfcValue;
    String director = directorController.text.trim();
    String duration = durationController.text.trim();
    String releaseYear = releaseYearController.text.trim();
    String starcast = starcastController.text.trim();

    // int views = 0;
//     try {
// /    } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//           content: Text("Invalid views format. Please enter a number.")));
//       setState(() {
//         isUploading = false;
//       });
//       return;
//     }

    if (title.isEmpty ||
        description.isEmpty ||
        category.isEmpty ||
        _imageFile == null ||
        (!_useUrl && _videoFile == null && videoUrlFromForm.isEmpty) ||
        cbfc == null ||
        director.isEmpty ||
        duration.isEmpty ||
        releaseYear.isEmpty ||
        starcast.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text("Please fill all required fields and upload files/URL")));

      setState(() {
        isUploading = false;
      });
      return;
    }

    try {
      String imageUrl = await _uploadFileToStorage(_imageFile!, 'images');
      String videoUrl;

      if (_useUrl) {
        videoUrl = videoUrlFromForm;
      } else {
        videoUrl = await _uploadFileToStorage(_videoFile!, 'videos');
      }

      //await videosController.addVideo(title, description, category, imageUrl, videoUrl);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video added successfully!")));

      // Call the notification function here, after successful video addition
      await sendNewVideoNotification(title); // Pass the video title

      Get.to(() => VideosPage());
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error adding video: $e")));
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
          ),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 1200),
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 30, 30, 30),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "Add New Video",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 32,
                              letterSpacing: 0.7,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          _buildMainContent(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we should use a row or column layout
        bool isWideScreen = constraints.maxWidth > 800;

        return Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade800),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade900.withOpacity(0.7),
                  Colors.black.withOpacity(0.3)
                ],
              )),
          padding: const EdgeInsets.all(24), // Increased Padding
          child: Flex(
            direction: isWideScreen ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.only(
                      right: isWideScreen ? 24.0 : 0.0,
                      bottom: isWideScreen ? 0.0 : 24.0), //Increased padding
                  child: _buildMediaSection(),
                ),
              ),
              Flexible(
                flex: 2,
                child: _buildFormSectionList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Media Upload",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
            fontSize: 20,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 16),
        _imageUrl.isEmpty ? _buildImagePlaceholder() : _buildImagePreview(),
        const SizedBox(height: 16),
        _buildUploadButton(
          icon: Icons.image,
          label: "Upload Thumbnail",
          onPressed: _pickImageWeb,
        ),
        const SizedBox(height: 24),
        _buildVideoSection(),
        const SizedBox(height: 16),
        _useUrl
            ? _buildUrlUploadSection()
            : _buildUploadButton(
                icon: Icons.videocam,
                label: "Upload Video File",
                onPressed: _pickVideoWeb,
              ),

        SizedBox(
          height: 20,
        ),
        _buildSubmitButton(),

        //   Row(
        //     children: [
        //       Checkbox(
        //         value: _useUrl,
        //         activeColor: Colors.blueAccent,
        //         onChanged: (value) {
        //           setState(() {
        //             _useUrl = value!;
        //             if (_useUrl) {
        //               _videoFile = null;
        //             }
        //           });
        //         },
        //       ),
        //       // Text(
        //       //   "Use Video URL (Live Video)",
        //       //   style: TextStyle(
        //       //       color: Colors.white.withOpacity(0.85), fontSize: 16),
        //       // ),
        //     ],
        //   ),
      ],
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF333333),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // More Rounded
        ),
        elevation: 4, // Subtle elevation
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _imageUrl,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildFormSectionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Video Details",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
            fontSize: 20,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 16),
        _buildFormSection(
            "Title", titleController, "Enter the title of the video"),
        const SizedBox(height: 16),
        _buildFormSection("Category", categoryController, "Enter the category"),
        const SizedBox(height: 16),
        _buildFormSection(
            "Description", descriptionController, "Enter a brief description",
            maxLines: 3),
        const SizedBox(height: 16),
        _buildDropdownSection(context),
        const SizedBox(height: 16),
        _buildFormSection(
            "Director", directorController, "Enter director's name"),
        const SizedBox(height: 16),
        _buildFormSection(
            "Duration", durationController, "Enter duration (e.g., 2h 19m)"),
        const SizedBox(height: 16),
        _buildFormSection("Release Year", releaseYearController,
            "Enter release year (e.g., 2025)"),
        const SizedBox(height: 16),
        _buildFormSection("Starcast", starcastController,
            "Enter starcast (e.g., Actor 1, Actor 2)"),
        const SizedBox(height: 16),
        // _buildFormSection("Views", viewsController, "Enter number of views"),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUrlUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFormSection("Video URL", videoUrlController,
            "Enter video URL (e.g., YouTube Live link)"),
        const SizedBox(height: 8),
        Text(
          "Note: For live videos, ensure the URL is a direct stream link.",
          style: TextStyle(color: Colors.grey.withOpacity(0.75), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDropdownSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "CBFC Rating",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _cbfcValue,
          decoration: InputDecoration(
            hintText: "Select CBFC Rating",
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFF444444),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
          dropdownColor: const Color(0xFF444444),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: cbfcOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _cbfcValue = newValue;
            });
          },
        ),
        if (_cbfcValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
              _getCbfcDescription(_cbfcValue!),
              style:
                  TextStyle(color: Colors.grey.withOpacity(0.75), fontSize: 13),
            ),
          ),
      ],
    );
  }

  String _getCbfcDescription(String cbfcRating) {
    switch (cbfcRating) {
      case "U":
        return "U – For all age groups. Safe, family-friendly content.";
      case "UA":
        return "UA – Parental guidance for kids under 12. May have mild themes.";
      case "U/A 13+":
        return "U/A 13+ – Suitable for 13+. Kids under 13 need adult with them.";
      case "U/A 16+":
        return "U/A 16+ – Suitable for 16+. Under 16 need adult supervision.";
      case "A":
        return "A – Adults only (18+). May have strong or mature content.";
      default:
        return "No description available.";
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.image,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    if (_useUrl) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.live_tv, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text(
              'Live Video Stream (URL)',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'A preview is not available for live streams. The video will be live once submitted.',
              style:
                  TextStyle(color: Colors.grey.withOpacity(0.75), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _videoFile == null
        ? Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.video_call,
                size: 48,
                color: Colors.grey,
              ),
            ),
          )
        : _isVideoLoaded && _chewieController != null
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Chewie(controller: _chewieController!),
                  ),
                ),
              )
            : const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
  }

  Widget _buildFormSection(
      String label, TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          //Replaced TextField with TextFormField
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.75)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFF444444),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            // New Focused Border Style
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: isUploading ? null : _submitVideo,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 189, 1, 1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
      child: isUploading
          ? const SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : const Text("Submit Video"),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:html' as html;
import 'package:admin/controllers/blog_controller.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class EditBlogPage extends StatefulWidget {
  final String blogId;

  const EditBlogPage({Key? key, required this.blogId}) : super(key: key);

  @override
  _EditBlogPageState createState() => _EditBlogPageState();
}

class _EditBlogPageState extends State<EditBlogPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  TextEditingController authorController = TextEditingController();
  html.File? _imageFile;

  String? imageUrl = '';
  final BlogController _controller = Get.find<BlogController>();

  bool _isLoading = false;  // Added loading state

  @override
  void initState() {
    super.initState();
    _fetchBlogData();
  }

  Future<void> _fetchBlogData() async {
    var blog = _controller.blogData.firstWhere((element) => element['id'] == widget.blogId);
    titleController.text = blog['title_en'] ?? blog['title'] ?? '';
    descriptionController.text = blog['description_en'] ?? blog['description'] ?? '';
    contentController.text = blog['content_en'] ?? blog['content'] ?? '';
    authorController.text = blog['author'];
    imageUrl = blog['urlToImage'];
    setState(() {});
  }

  void _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final reader = html.FileReader();
      reader.readAsDataUrl(files[0]);

      reader.onLoadEnd.listen((e) {
        setState(() {
          imageUrl = reader.result as String;
          _imageFile = files[0];
        });
      });
    });
  }

  Future<String> uploadFileToStorage(html.File file, String folder) async {
    try {
      final firebase_storage.Reference storageRef = firebase_storage.FirebaseStorage.instance
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

  Future<void> _saveEditedBlog() async {
    setState(() {
      _isLoading = true;  // Set loading to true when the update process starts
    });

    String? uploadedImageUrl;

    // Check if a new image was picked, and upload it if so
    if (_imageFile != null) {
      uploadedImageUrl = await uploadFileToStorage(_imageFile!, 'blog_images');
    }

    try {
      // Prepare a map of updated fields
      Map<String, dynamic> updatedFields = {};

      if (titleController.text.isNotEmpty) {
        updatedFields['title_en'] = titleController.text;
        updatedFields['title_hi'] = titleController.text;
      }
      if (descriptionController.text.isNotEmpty) {
        updatedFields['description_en'] = descriptionController.text;
        updatedFields['description_hi'] = descriptionController.text;
      }
      if (contentController.text.isNotEmpty) {
        updatedFields['content_en'] = contentController.text;
        updatedFields['content_hi'] = contentController.text;
      }
      if (authorController.text.isNotEmpty) {
        updatedFields['author'] = authorController.text;
      }
      if (uploadedImageUrl != null) {
        updatedFields['urlToImage'] = uploadedImageUrl;
      }

      // Call the controller method to update the blog with specific fields
      await _controller.updateBlog(
        blogId: widget.blogId,
        updatedFields: updatedFields,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Blog updated successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Get.back();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update blog. Please try again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;  // Set loading to false when the process ends
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Blog"),
        backgroundColor: const Color.fromARGB(255, 19, 24, 27),
        elevation: 4.0,
        shadowColor: Colors.black54,
      ),
      body: Row(
        children: [

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
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Edit Blog",
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildImageSection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormSection("Author", authorController, "Enter the author's name"),
                                const SizedBox(height: 16),
                                _buildFormSection("Title", titleController, "Enter the blog title"),
                                const SizedBox(height: 16),
                                _buildFormSection("Description", descriptionController, "Enter a brief description", maxLines: 3),
                                const SizedBox(height: 16),
                                _buildFormSection("Content", contentController, "Enter the blog content", maxLines: 5),
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
        imageUrl!.isEmpty
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
            : Image.network(imageUrl!, height: 300, fit: BoxFit.contain),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _pickImage,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 37, 35, 35),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Change Image"),
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
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _saveEditedBlog,
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

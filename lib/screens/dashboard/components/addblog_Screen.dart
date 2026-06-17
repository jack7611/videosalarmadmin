import 'dart:html' as html;
import 'package:admin/controllers/blog_controller.dart';
import 'package:admin/screens/dashboard/components/Blog_page.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AddBlogPage extends StatefulWidget {
  const AddBlogPage({Key? key}) : super(key: key);

  @override
  _AddBlogPageState createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  final BlogController blogController = Get.find();

  TextEditingController authorController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController sourceIdController = TextEditingController();
  TextEditingController sourceNameController = TextEditingController();
  TextEditingController urlController = TextEditingController();
  TextEditingController contentController =
      TextEditingController(); // Content field

  html.File? _imageFile;
  String _imageUrl = '';
  bool isUploading = false;

  // Upload file to Firebase Storage
  Future<String> uploadFileToStorage(html.File file, String folder) async {
    try {
      final firebase_storage.Reference storageRef = firebase_storage
          .FirebaseStorage.instance
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

  // Method to pick image from file system (Web-specific)
  void _pickImageWeb() async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final reader = html.FileReader();
      reader.readAsDataUrl(files[0]);

      reader.onLoadEnd.listen((e) {
        setState(() {
          _imageUrl = reader.result as String;
          _imageFile = files[0];
        });
      });
    });
  }

  // Submit Blog and Image to Firestore
  Future<void> _submitBlog() async {
    setState(() {
      isUploading = true;
    });

    String title = titleController.text.trim();
    String description = descriptionController.text.trim();
    String author = authorController.text.trim();
    String category = categoryController.text.trim();
    String sourceId = sourceIdController.text.trim();
    String sourceName = sourceNameController.text.trim();
    String url = urlController.text.trim();
    String content = contentController.text.trim();

    if (title.isEmpty ||
        description.isEmpty ||
        author.isEmpty ||
        _imageFile == null ||
        category.isEmpty ||
        sourceId.isEmpty ||
        sourceName.isEmpty ||
        url.isEmpty ||
        content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please fill all fields and upload an image")));
      setState(() {
        isUploading = false;
      });
      return;
    }

    try {
      // Upload image to Firebase Storage
      String urlToImage = await uploadFileToStorage(_imageFile!, 'blog_images');

      // Prepare blog data
      Map<String, dynamic> blogData = {
        'author': author,
        'title_en': title,
        'title_hi': title,
        'description_en': description,
        'description_hi': description,
        'category': category,
        'source': {
          'id': sourceId,
          'name': sourceName,
        },
        'url': url,
        'content_en': content,
        'content_hi': content,
        'urlToImage': urlToImage,
        'publishedAt': DateTime.now().toIso8601String(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('blogsnew').add(blogData);

      blogController.fetchBlogs();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Blog added successfully!")));
      Get.to(() => BlogPage());
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error adding blog: $e")));
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
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: const Text(
                          "Add New Blog",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildFormSection("Author", authorController,
                          "Enter the author's name"),
                      const SizedBox(height: 16),
                      _buildFormSection("Title", titleController,
                          "Enter the title of the blog"),
                      const SizedBox(height: 16),
                      _buildFormSection("Description", descriptionController,
                          "Enter a brief description",
                          maxLines: 4),
                      const SizedBox(height: 16),
                      _buildFormSection("Category", categoryController,
                          "Enter the category of the blog"),
                      const SizedBox(height: 16),
                      _buildFormSection("Source ID", sourceIdController,
                          "Enter the source ID"),
                      const SizedBox(height: 16),
                      _buildFormSection("Source Name", sourceNameController,
                          "Enter the source name"),
                      const SizedBox(height: 16),
                      _buildFormSection(
                          "URL", urlController, "Enter the URL of the blog"),
                      const SizedBox(height: 16),
                      _buildFormSection("Content", contentController,
                          "Enter the full content of the blog",
                          maxLines: 6),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _pickImageWeb,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 37, 35, 35),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Pick Image from File"),
                      ),
                      if (_imageUrl.isNotEmpty) _buildImagePreview(),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isUploading ? null : _submitBlog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 37, 35, 35),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isUploading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Submit Blog"),
                      ),
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

  Widget _buildFormSection(
      String label, TextEditingController controller, String hint,
      {int maxLines = 1}) {
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
            border: InputBorder.none,
            filled: true,
            fillColor: const Color.fromARGB(255, 40, 40, 40),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.network(
            _imageUrl,
            height: 150,
            width: 150,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _imageUrl = '';
              _imageFile = null;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Remove Image"),
        ),
      ],
    );
  }
}

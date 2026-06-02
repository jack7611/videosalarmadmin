import 'package:admin/controllers/blog_controller.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BlogDetailPage extends StatelessWidget {
  final String blogId;

  const BlogDetailPage({Key? key, required this.blogId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final BlogController blogController = Get.find();

    return Scaffold(
      appBar: CustomAppBar(),
      body: Row(
        children: [
          // Side menu
   
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Obx(() {
                // Find the selected blog based on the blogId passed
                var selectedBlog = blogController.blogData.firstWhere((blog) => blog['id'] == blogId, orElse: () => {});

                if (selectedBlog.isEmpty) {
                  return const Center(child: Text("Blog not found", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)));
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Blog image (if available)
                      if (selectedBlog['urlToImage'] != null && selectedBlog['urlToImage'] != '')
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              selectedBlog['urlToImage'],
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                      // Title
                      Text(
                        selectedBlog['title'],
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 15),

                      // Author and Date
                      Row(
                        children: [
                          Text(
                            "By ${selectedBlog['author']}",
                            style: const TextStyle(fontSize: 18, color: Colors.white70),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            "Published on: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(selectedBlog['publishedAt']))}",
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Blog content
                      Text(
                        selectedBlog['content'],
                        style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.white),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 19, 24, 27), // Dark background for the whole page
    );
  }
}

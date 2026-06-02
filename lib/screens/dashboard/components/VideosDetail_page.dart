// import 'package:admin/controllers/Videos_controller.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:flutter/material.dart';
// import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ViewDetailsPage extends StatelessWidget {
  final String documentId;
  final String category;
  final String createdAt;
  final String title;
  final String description;
  final String videoUrl;

  const ViewDetailsPage({
    Key? key,
    required this.documentId,
    required this.category,
    required this.createdAt,
    required this.title,
    required this.description,
    required this.videoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final VideosController videosController = Get.put(VideosController());

    return Scaffold(
      appBar: CustomAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine screen size for responsive layout
          bool isLargeScreen = constraints.maxWidth > 800;

          return Row(
            children: [
              // Side Menu moved to the left side for larger screens
           

              // Main content area (Video and Text Content)
              Expanded(
                flex: isLargeScreen ? 2 : 1, // More space for larger screens
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Video Player Section (bigger size)
                        Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                spreadRadius: 1,
                                blurRadius: 15,
                              ),
                            ],
                          ),
                          // Adjust height dynamically based on screen size
                          height: constraints.maxWidth > 800
                              ? 550
                              : 250, // Smaller height for mobile screens
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Chewie(
                              controller: ChewieController(
                                videoPlayerController:
                                    VideoPlayerController.network(videoUrl),
                                autoPlay: true,
                                looping: true,
                                placeholder: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title and Metadata Section
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$category | Created At: $createdAt",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description Section
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // "More from this Author" Section on larger screens (could be added here)
            ],
          );
        },
      ),
    );
  }
}

import 'package:admin/controllers/custom_notification_controller.dart';
import 'package:admin/screens/main/components/create_notification_screen.dart'; // Import Create Screen
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CustomNotificationScreen extends StatelessWidget {
  const CustomNotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    final CustomNotificationController controller =
        Get.put(CustomNotificationController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Custom Notifications",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // Create New Button
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: () => Get.to(() => const CreateNotificationScreen()),
              icon: const Icon(Icons.add, size: 20),
              label: const Text("Create New"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1), // Purple accent
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List Header
            Row(
              children: [
                const Icon(Icons.history, color: Colors.white70),
                const SizedBox(width: 8),
                const Text(
                  "Notification History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Obx(() => Text(
                      "${controller.notificationHistory.length} sent",
                      style: const TextStyle(color: Colors.white38),
                    )),
              ],
            ),
            const SizedBox(height: 16),

            // Notification List
            Expanded(
              child: Obx(() {
                if (controller.notificationHistory.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 60, color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text(
                          "No notifications sent yet.",
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () =>
                              Get.to(() => const CreateNotificationScreen()),
                          icon: const Icon(Icons.add),
                          label: const Text("Send your first notification"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.notificationHistory.length,
                  itemBuilder: (context, index) {
                    var notif = controller.notificationHistory[index];
                    bool isTest = notif['type'] == 'Test Device';

                    return Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isTest
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isTest ? Icons.developer_mode : Icons.campaign,
                            color:
                                isTest ? Colors.greenAccent : Colors.blueAccent,
                          ),
                        ),
                        title: Text(
                          notif['title'] ?? 'No Title',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (notif['body'] != null &&
                                notif['body'].isNotEmpty)
                              Text(
                                notif['body'],
                                style: const TextStyle(color: Colors.white70),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    notif['type'] ?? 'Unknown',
                                    style: TextStyle(
                                        color: isTest
                                            ? Colors.greenAccent
                                            : Colors.blueAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTimestamp(notif['timestamp']),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    try {
      DateTime date = (timestamp as Timestamp).toDate();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return "Unknown Date";
    }
  }
}

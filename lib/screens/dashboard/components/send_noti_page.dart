// lib/pages/notification_page.dart

import 'package:admin/screens/dashboard/components/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final NotificationController notificationController =
        Get.put(NotificationController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildNotificationForm(context, notificationController),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'New Video Notification',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Video Alert',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Notify users when a new video is uploaded. Users receive: "New Video Uploaded! [title] is now available."',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white60,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationForm(
      BuildContext context, NotificationController controller) {
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
          // Form Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.message_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Text(
                'Message Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Input Fields
          _buildTextField(
            controller: controller.titleController,
            label: 'Video Name (e.g., Kedarnath Episode 1)',
            icon: Icons.movie_creation_rounded,
            maxLength: 60,
          ),
          const SizedBox(height: 24),

          // Warning Box
          _buildWarningBox(),
          const SizedBox(height: 32),

          // Send Button
          _buildSendButton(context, controller),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          counterStyle: const TextStyle(color: Colors.white54),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          filled: true,
          fillColor: const Color(0xFF0F0F0F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Users subscribed to new-video alerts will receive: "New Video Uploaded! [video name] is now available to watch." This cannot be undone.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(
      BuildContext context, NotificationController controller) {
    return SizedBox(
      width: double.infinity,
      child: Obx(() {
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // Disable button if title is empty or if loading
            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
          ),
          onPressed: controller.isTitleValid.value && !controller.isLoading.value
              ? () => _showConfirmationDialog(context, controller)
              : null,
          icon: controller.isLoading.value
              ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 20),
          label: Text(
            controller.isLoading.value ? 'Sending...' : 'Send Notification',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        );
      }),
    );
  }

  void _showConfirmationDialog(
      BuildContext context, NotificationController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.send_to_mobile_rounded,
                  color: Color(0xFF6366F1), size: 28),
              SizedBox(width: 12),
              Text(
                'Confirm Broadcast',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to send this notification to all users?\n\nTitle: "${controller.titleController.text}"',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog first
                controller.sendNotification(); // Then send the notification
              },
              child: const Text(
                'Confirm & Send',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
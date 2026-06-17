import 'package:admin/controllers/custom_notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateNotificationScreen extends StatelessWidget {
  const CreateNotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final CustomNotificationController controller =
        Get.find<CustomNotificationController>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildNotificationForm(context, controller),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Festival / Event Notification',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Festival / Event Broadcast',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Send a custom message to ALL users — Diwali wishes, Holi greetings, app announcements, special offers, etc.',
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
      BuildContext context, CustomNotificationController controller) {
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
            label: 'Message Title (e.g., Happy Diwali! 🪔)',
            icon: Icons.celebration_rounded,
            maxLength: 60,
          ),
          _buildTextField(
            controller: controller.bodyController,
            label: 'Notification Body (Optional)',
            icon: Icons.article_rounded,
            maxLines: 4,
            maxLength: 150,
          ),

          const SizedBox(height: 16),

          // Test Mode Toggle
          Obx(() => Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F0F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SwitchListTile(
                  title: const Text("Send to Test Device Only",
                      style: TextStyle(color: Colors.white)),
                  secondary: Icon(Icons.developer_mode,
                      color: controller.isTestMode.value
                          ? const Color(0xFF6366F1)
                          : Colors.grey),
                  value: controller.isTestMode.value,
                  onChanged: (val) => controller.isTestMode.value = val,
                  activeColor: const Color(0xFF6366F1),
                  contentPadding: EdgeInsets.zero,
                ),
              )),

          // Test Token Input
          Obx(() => controller.isTestMode.value
              ? AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(top: 16),
                  child: _buildTextField(
                    controller: controller.testTokenController,
                    label: "FCM Device Token",
                    icon: Icons.key,
                  ),
                )
              : const SizedBox.shrink()),

          const SizedBox(height: 24),

          // Warning Box (Conditional Text)
          Obx(() => _buildWarningBox(isTest: controller.isTestMode.value)),

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

  Widget _buildWarningBox({required bool isTest}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isTest
                  ? 'This message will be sent ONLY to the specified test device.'
                  : 'This message will be sent as a broadcast to ALL users on both Android and iOS. This action cannot be undone.',
              style: const TextStyle(
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
      BuildContext context, CustomNotificationController controller) {
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
            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
          ),
          onPressed:
              controller.isTitleValid.value && !controller.isLoading.value
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
      BuildContext context, CustomNotificationController controller) {
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
                'Confirm Send',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to send this notification?\n\nTitle: "${controller.titleController.text}"\nMode: ${controller.isTestMode.value ? "Test Device" : "Broadcast"}',
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
            Obx(() => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              ),
              onPressed: controller.isLoading.value
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      controller.sendNotification();
                    },
              child: const Text(
                'Confirm & Send',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )),
          ],
        );
      },
    );
  }
}

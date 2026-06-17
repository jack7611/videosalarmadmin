// lib/controllers/notification_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NotificationController extends GetxController {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  var isLoading = false.obs;
  var isTitleValid = false.obs; // To enable/disable the send button

  @override
  void onInit() {
    super.onInit();
    // Add a listener to the title controller to update validation state
    titleController.addListener(() {
      isTitleValid.value = titleController.text.trim().isNotEmpty;
    });
  }

  Future<void> sendNotification() async {
    if (isLoading.value) return;
    if (!isTitleValid.value) {
      Get.snackbar(
        'Validation Error',
        'Notification title cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    // Your provided API endpoint
    const String apiUrl = 'https://videosalarm.com/api/sendNotification';
    final headers = {'Content-Type': 'application/json'};
    
    // Per your backend code, only the 'title' is required in the body.
    // The server constructs the notification body itself.
    final body = json.encode({'title': titleController.text.trim()});

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          'Success',
          'Notification sent successfully to all users.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981), // Success Green
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        // Clear fields after a successful send
        titleController.clear();
        bodyController.clear();
      } else {
        final responseBody = json.decode(response.body);
        final errorMessage = responseBody['message'] ?? 'An unknown server error occurred.';
        Get.snackbar(
          'API Error',
          'Failed to send notification: $errorMessage (Code: ${response.statusCode})',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444), // Error Red
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      // Handles network errors, timeouts, etc.
      Get.snackbar(
        'Network Error',
        'Could not connect to the server. Please check your connection. Error: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444), // Error Red
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    bodyController.dispose();
    super.onClose();
  }
}
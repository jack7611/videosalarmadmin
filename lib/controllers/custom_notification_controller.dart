import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CustomNotificationController extends GetxController {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final testTokenController = TextEditingController(); // For test device token

  var isLoading = false.obs;
  var isTitleValid = false.obs; 
  var isTestMode = false.obs; // Toggle for test device

  // Observable list for notification history
  var notificationHistory = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    titleController.addListener(_validateForm);
    _fetchNotificationHistory();
  }


  void _validateForm() {
    isTitleValid.value = titleController.text.trim().isNotEmpty;
  }

  // Fetch sent notifications from Firestore
  void _fetchNotificationHistory() {
    FirebaseFirestore.instance
        .collection('admin_notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      notificationHistory.value = snapshot.docs.map((doc) {
        var data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> sendNotification() async {
    // Hard guard — prevents double-send if called twice before isLoading propagates
    if (isLoading.value) return;

    if (!isTitleValid.value) {
      Get.snackbar('Error', 'Title is required', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (isTestMode.value && testTokenController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Test Device Token is required', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    const String apiUrl = 'https://videosalarm.com/api/broadcastNotification';
    final headers = {'Content-Type': 'application/json'};

    Map<String, dynamic> requestBody = {
      'title': titleController.text.trim(),
      'body': bodyController.text.trim(),
    };

    // If in test mode, include the token
    if (isTestMode.value) {
      requestBody['token'] = testTokenController.text.trim();
    }
    
    print("Request URL: $apiUrl");
    print("Request Body: ${json.encode(requestBody)}");

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(requestBody),
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("API Success. Writing to Firestore...");
        // Log to Firestore
        try {
          await FirebaseFirestore.instance.collection('admin_notifications').add({
            'title': titleController.text.trim(),
            'body': bodyController.text.trim(),
            'type': isTestMode.value ? 'Test Device' : 'Broadcast',
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'Sent',
          });
          print("Firestore Write Success.");
        } catch (dbError) {
          print("Firestore Write Failed: $dbError");
          Get.snackbar('Error', 'Notification sent but DB write failed: $dbError', backgroundColor: Colors.orange, colorText: Colors.white);
        }

        Get.snackbar(
          'Success',
          'Notification sent!',
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
        _clearForm();
        if (Get.isDialogOpen ?? false) Get.back(); 
      } else {
        print("API Failed.");
        Get.snackbar('Error', 'Failed: ${response.statusCode} - ${response.body}', backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print("Network Exception: $e");
      Get.snackbar('Error', 'Network Error: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  void _clearForm() {
    titleController.clear();
    bodyController.clear();
    testTokenController.clear();
    isTestMode.value = false;
  }

  @override
  void onClose() {
    titleController.dispose();
    bodyController.dispose();
    testTokenController.dispose();
    super.onClose();
  }
}

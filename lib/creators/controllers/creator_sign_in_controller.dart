import 'dart:async';
import 'dart:html' as html;
import 'package:admin/creators/screens/creator_dashboard_screen.dart';
import 'package:admin/screens/main/components/admin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/creators/screens/creator_sign_in_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatorSignInController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  
  // Focus nodes
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    _checkCreatorStatus();
  }

  void _checkCreatorStatus() {
    String? isCreatorLoggedIn = html.window.localStorage['isCreatorLoggedIn'];
    String? lastLoginTime = html.window.localStorage['lastLoginTime'];
    if (isCreatorLoggedIn == 'true' && isCreatorLoggedIn != null) {
       if (lastLoginTime != null) {
        DateTime lastLogin = DateTime.parse(lastLoginTime);
        if (DateTime.now().difference(lastLogin).inHours < 12) {
          // If the last login was within 12 hours, redirect to main screen
          Get.offAll(() => CreatorDashboardScreen());
          return;
        }
      }
    }
    // If not logged in or session expired, clear storage
    html.window.localStorage.clear();
  }

  Future<void> signIn() async {
    errorMessage.value = '';
    if (!formKey.currentState!.validate()) return;

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    if (!formKey.currentState!.validate()) {
      return; // If form is invalid, stop execution
    }

    isLoading.value = true;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('creators')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .where('active', isEqualTo: true) // Only active creators
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        // Success
        html.window.localStorage['isCreatorLoggedIn'] = 'true';
        html.window.localStorage['creatorId'] = doc.id;
        html.window.localStorage['creatorName'] = doc['name'] ?? 'Creator';

        Get.offAll(() => const CreatorDashboardScreen());
        Get.snackbar("Success", "Welcome back, ${doc['name']}",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        _showError("Wrong creator credential");
      }
    } catch (e) {
       _showError("Login failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Sign-out function for creator
  void signOut() async {
    // Clear localStorage to sign out
    html.window.localStorage.remove('isCreatorLoggedIn');
    html.window.localStorage.remove('creatorId');
    html.window.localStorage.remove('creatorName');
    
    // Ensure Firebase Auth is sign out if used
    if (FirebaseAuth.instance.currentUser != null) {
       await FirebaseAuth.instance.signOut();
    }

    errorMessage.value = ''; // Clear any previous error messages
    Get.offAll(() => const CreatorSignInPage());
  }

  // Timer for auto-clearing error
  Timer? _errorTimer;

  void _showError(String message) {
    errorMessage.value = message;
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 15), () {
      errorMessage.value = '';
    });
  }


  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.onClose();
  }
}

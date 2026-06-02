import 'dart:async';
import 'dart:html' as html; // For accessing local storage
import 'package:admin/screens/main/components/admin_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/screens/main/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSignInController extends GetxController {
  final formKey = GlobalKey<FormState>(); // Form key for validation
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    _checkAdminStatus();
  }

  // Check if admin is already signed in using local storage
  void _checkAdminStatus() async {
    String? isLoggedIn = html.window.localStorage['isLoggedIn'];
    String? lastLoginTime = html.window.localStorage['lastLoginTime'];

    if (isLoggedIn != null && isLoggedIn == 'true') {
      if (lastLoginTime != null) {
        DateTime lastLogin = DateTime.parse(lastLoginTime);
        if (DateTime.now().difference(lastLogin).inHours < 12) {
          // If the last login was within 12 hours, redirect to main screen
          Get.offAll(() => MainScreen());
          return;
        }
      }
    }
    // If not logged in or session expired, clear storage
    html.window.localStorage.clear();
  }

  // Sign-in function for admin
  void signIn() async {
    errorMessage.value = ''; // Clear previous errors
    if (!formKey.currentState!.validate()) {
      return; // If form is invalid, stop execution
    }
    

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
      // Fetch admin details from Firestore
      DocumentSnapshot adminDoc =
          await _firestore.collection('admin').doc('admin1').get();

      if (adminDoc.exists) {
        String storedEmail = adminDoc['email'];
        String storedPassword = adminDoc['password'];

        if (email == storedEmail && password == storedPassword) {
          // Successful login: Store the login state and timestamp in localStorage
          html.window.localStorage['isLoggedIn'] = 'true';
          html.window.localStorage['lastLoginTime'] = DateTime.now().toIso8601String();

          Get.offAll(() => MainScreen());
          Get.snackbar(
            'Success',
            'Sign-in successful!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          _showError('Invalid admin credential');
        }
      } else {
        _showError('Invalid admin credential');
      }
    } catch (e) {
      _showError('Failed to sign in: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Sign-out function for admin
  void signOut() async {
    // Clear localStorage to sign out
    html.window.localStorage.remove('isLoggedIn');
    html.window.localStorage.remove('lastLoginTime');
    
    // Ensure Firebase Auth is also signed out to prevent conflicts
    await FirebaseAuth.instance.signOut();
    
    errorMessage.value = ''; // Clear any previous error messages
    Get.offAll(() => const AdminSignInPage());
  }

  // Timer for auto-clearing error
  Timer? _errorTimer;

  // Show error snackbar
  void _showError(String message) {
    errorMessage.value = message;
    
    // Cancel previous timer if exists
    _errorTimer?.cancel();
    
    // Set timer to clear error after 15 seconds
    _errorTimer = Timer(const Duration(seconds: 10), () {
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

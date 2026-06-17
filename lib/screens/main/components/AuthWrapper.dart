import 'package:admin/screens/main/components/admin_page.dart';
import 'package:admin/screens/main/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html; // For accessing local storage

// Define the AuthWrapper widget to protect routes
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Only show MainScreen if admin explicitly logged in via credentials
        if (html.window.localStorage['isLoggedIn'] == 'true') {
          return MainScreen();
        }
        return const AdminSignInPage();
      },
    );
  }
}

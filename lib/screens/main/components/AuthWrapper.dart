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

        // If the user is logged in
        if (snapshot.hasData) {
          // Persist login state in localStorage
          if (html.window.localStorage['isLoggedIn'] == null) {
            html.window.localStorage['isLoggedIn'] = 'true';
          }
          return MainScreen();
        } else {
          // If the user is not logged in
          if (html.window.localStorage['isLoggedIn'] == 'true') {
            return MainScreen();
          }
          // Otherwise, return the sign-in page
          return const AdminSignInPage();
        }
      },
    );
  }
}

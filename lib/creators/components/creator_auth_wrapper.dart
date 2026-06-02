import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:admin/creators/screens/creator_sign_in_page.dart';
import 'package:admin/creators/screens/creator_dashboard_screen.dart';

class CreatorAuthWrapper extends StatelessWidget {
  const CreatorAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = html.window.localStorage['isCreatorLoggedIn'] == 'true';

    if (isLoggedIn) {
      return const CreatorDashboardScreen();
    } else {
      return const CreatorSignInPage();
    }
  }
}

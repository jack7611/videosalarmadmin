import 'package:admin/controllers/menu_app_controller.dart';
import 'package:admin/screens/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/side_menu.dart';
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
          DashboardScreen(),
        SizedBox(height: 40,),
         _buildFooter(context)
          ],
        ),
      ),
    );
  }

    Widget _buildFooter(context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height*0.12,
      color: Colors.black,
      child: Center(
        child: Text(
          "© 2025 VideosAlarm Admin. All Rights Reserved.",
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ),
    );
  }

}

import 'package:admin/controllers/User_controller.dart';
import 'package:admin/controllers/Videos_controller.dart';
import 'package:admin/responsive.dart';
import 'package:admin/screens/dashboard/components/my_fields.dart';
// import 'package:admin/screens/dashboard/components/recent_files.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../constants.dart';

class DashboardScreen extends StatelessWidget {
  final UserController userController = Get.find<UserController>();
  final VideosController videoController = Get.find<VideosController>();

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: SingleChildScrollView(
        
        primary: false,
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            // Header(),
            SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                                            MyFiles(),

                                                                  SizedBox(height: defaultPadding),

                      // UserJoinGraph(),

                      if (Responsive.isMobile(context))
                        SizedBox(height: defaultPadding),
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context))
                  SizedBox(width: defaultPadding),
              ],
            ),
          
          ],
        ),
      ),
    );
  }
}

// import 'package:admin/controllers/Videos_controller.dart';
// import 'package:admin/models/Videos.dart';
import 'package:admin/screens/dashboard/components/sub.dart';
import 'package:admin/screens/dashboard/components/subscription_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:get/get.dart';
import 'package:admin/controllers/User_controller.dart';
import 'package:admin/models/User.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html; // Import dart:html for web URL launching

class SubscriptionPage extends StatelessWidget {
  SubscriptionPage({Key? key}) : super(key: key);
  final subscriptionService = SubscriptionService();

  Future<void> updatePaymentMethods() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot usersSnapshot = await firestore.collection('users').get();

    const batchSize = 500;
    final docs = usersSnapshot.docs;

    for (int i = 0; i < docs.length; i += batchSize) {
      final batch = firestore.batch();
      final chunk = docs.skip(i).take(batchSize);

      for (var doc in chunk) {
        final data = doc.data() as Map<String, dynamic>;

        final subscriptionType = data['SubscriptionType'];
        final purchaseToken = data['PurchaseToken']?.toString();

        String method;

        if (subscriptionType == 'com.videosalarm.subscription.premium') {
          method = 'ios';
        } else if (subscriptionType == 'vip_plan_id') {
          if (purchaseToken != null && purchaseToken.startsWith('pay_')) {
            method = 'razorpay';
          } else {
            method = 'android';
          }
        } else {
          method = 'unknown';
        }

        batch.update(doc.reference, {'paymentMethod': method});
      }

      await batch.commit();
      print("Processed batch ${i ~/ batchSize + 1}");
    }

    print("✅ Finished updating all user documents with payment methods.");
  }

  final Map<String, dynamic> subscription = const {
    "name": "Premium Plan",
    "price": "\₹99/Year",
    "features":
        "Unleash the full potential! Exclusive New Movies, Music & Blogs, Ad-Free Experience, Downloadable Content",
    "color": Color(
        0xFF1E88E5), // Changed the color to a darker blue similar to the provided theme
    "benefits": ["Exclusive Content", "High-Quality Playback"]
  };

  @override
  Widget build(BuildContext context) {
    // final VideosController videoController = Get.put(VideosController());
    final UserController userController = Get.put(UserController());

    return Scaffold(
      appBar: CustomAppBar(),
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        // Added SafeArea to avoid overlap with system UI
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Side Menu (always visible on web)
            // SizedBox(
            //   width: 250,
            //   child: Container(
            //     color: const Color(0xFF1E1E1E),
            //     child: const SideMenu(),
            //   ),
            // ),
            // Main Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child:
                    LayoutBuilder(// Use LayoutBuilder to adapt to screen size
                        builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      // Ensure content is at least the screen height
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Page Header
                          Padding(
                            padding: const EdgeInsets.only(bottom: 32.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subscription Management',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    updatePaymentMethods();
// _launchImageURL(updatePaymentMethods
                                    //     'https://play.google.com/console/developers/8760598417069670906/app/4972286785560733177/subscriptions');
                                    // print("Add New Subscription");
                                  },
                                  icon: const Icon(Icons.add,
                                      color: Colors.white),
                                  label: const Text("cription",
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF303F9F),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                    textStyle: const TextStyle(fontSize: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Hero Section
                          HeroSection(subscription: subscription),

                          const SizedBox(height: 48),

                          // Active Subscribers Section
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Active Subscribers',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Get.to(() => const UserPagesubs());
                                    print("View All Subscribers");
                                  },
                                  icon: const Icon(Icons.visibility,
                                      color: Colors.white),
                                  label: const Text("View All",
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade800,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                    textStyle: const TextStyle(fontSize: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // User Table
                          SubscriptionTable(userController: userController),
                          SizedBox(height: 20) //Add spacing bottom
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchImageURL(String url) {
    // This will open the image URL in a new browser window/tab
    html.window.open(url, '_blank');
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({Key? key, required this.subscription}) : super(key: key);

  final Map<String, dynamic> subscription;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 600;
          return Container(
            constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 350),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              color: subscription['color'] ?? const Color(0xFF2C2C2C),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32.0),
            child: IntrinsicHeight(
              child: Flex(
                // Use Flex to handle different screen sizes
                direction: isSmallScreen
                    ? Axis.vertical
                    : Axis.horizontal, // Stack vertically on small screens
                children: [
                  // Plan Details (Left Side)
                  Expanded(
                    flex: 2, // Takes more space on larger screens
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: isSmallScreen ? 28 : 32,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subscription['price'],
                          style: TextStyle(
                            fontSize: isSmallScreen ? 20 : 24,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          subscription['features'],
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 14,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Benefits List & Subscribe Button (Right Side)
                  Expanded(
                    flex: 1, // Smaller space for benefits
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: isSmallScreen
                            ? 0.0
                            : 24.0, // Remove left padding on small screens
                        top: isSmallScreen
                            ? 24.0
                            : 0.0, // Add top padding on small screens
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Key Benefits:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: (subscription['benefits']
                                        as List<String>)
                                    .map((benefit) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6.0),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle,
                                                  color: Colors.greenAccent,
                                                  size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                benefit,
                                                style: TextStyle(
                                                  fontSize:
                                                      isSmallScreen ? 14 : 16,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SubscriptionTable extends StatelessWidget {
  const SubscriptionTable({Key? key, required this.userController})
      : super(key: key);

  final UserController userController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (userController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      } else {
        final activeUsers =
            userController.users.where((user) => user.active == true).toList();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: LayoutBuilder(
              // Use LayoutBuilder to determine table width
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth < 768
                      ? 768
                      : MediaQuery.of(context).size.width -
                          300, // Minimum width for small screens
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                        const Color.fromARGB(255, 14, 18, 21)),
                    dataRowMaxHeight: 60,
                    columnSpacing: 30.0,
                    columns: [
                      DataColumn(
                          label: Expanded(
                              child: Text('Name',
                                  style:
                                      _headerTextStyle()))), // Expanded columns for even distribution
                      // DataColumn(label: Expanded(child: Text('Email', style: _headerTextStyle()))),
                      DataColumn(
                          label: Expanded(
                              child:
                                  Text('Status', style: _headerTextStyle()))),
                      DataColumn(
                          label: Expanded(
                              child: Text('Expiry Date',
                                  style: _headerTextStyle()))),
                      DataColumn(
                          label: Expanded(
                              child: Text('Plan name',
                                  style: _headerTextStyle()))),
                      DataColumn(
                          label: Expanded(
                              child: Text('Price', style: _headerTextStyle()))),
                    ],
                    rows: activeUsers.take(5).map((user) {
                      return DataRow(
                        cells: [
                          DataCell(Text(user.name ?? 'N/A',
                              style: _cellTextStyle())),
                          // DataCell(Text(user.email ?? 'N/A', style: _cellTextStyle())),
                          DataCell(Text(
                              user.active ?? false ? 'Active' : 'Inactive',
                              style: _cellTextStyle())),
                          DataCell(Text(
                              user.subscriptionExpiryDate != null
                                  ? DateFormat('MMMM d, yyyy')
                                      .format(user.subscriptionExpiryDate!)
                                  : 'N/A',
                              style: _cellTextStyle())),
                          DataCell(Text(
                              user.subscriptionType == 'vip_plan_id' ||
                                      user.subscriptionType ==
                                          'com.videosalarm.subscription.premium'
                                  ? 'Premium'
                                  : 'N/A',
                              style: _cellTextStyle())),
                          DataCell(Text(
                              user.subscriptionType == 'vip_plan_id' ||
                                      user.subscriptionType ==
                                          'com.videosalarm.subscription.premium'
                                  ? '₹99'
                                  : 'N/A',
                              style: _cellTextStyle())),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        );
      }
    });
  }

  void _showEditUserDialog(
      BuildContext context, UserController userController, User user) {
    // userController.emailController.text = user.email ?? '';
    userController.nameController.text = user.name ?? '';
    userController.phoneController.text = user.phone ?? '';
    userController.checkTermsAndCondition.value =
        user.checkTermsAndCondition ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text('Edit User',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // _buildTextField(controller: userController.emailController, label: 'Email'),
                _buildTextField(
                    controller: userController.nameController, label: 'Name'),
                _buildTextField(
                    controller: userController.phoneController, label: 'Phone'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                User updatedUser = User(
                  id: user.id,
                  checkTermsAndCondition:
                      userController.checkTermsAndCondition.value,
                  createdAt: user.createdAt,
                  // email: userController.emailController.text.isEmpty ? null : userController.emailController.text,
                  name: userController.nameController.text.isEmpty
                      ? null
                      : userController.nameController.text,
                  phone: userController.phoneController.text.isEmpty
                      ? null
                      : userController.phoneController.text,
                );
                userController.updateUser(user.id, updatedUser);
                Navigator.of(context).pop();
              },
              child: const Text('Save Changes',
                  style: TextStyle(
                      color: Color(0xFF303F9F), fontSize: 18)), //Deep Purple
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller, required String label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white, fontSize: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF3F51B5)), //Indigo 500
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.deepPurple.shade400),
          ),
        ),
      ),
    );
  }

  TextStyle _headerTextStyle() {
    return const TextStyle(
        fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white);
  }

  TextStyle _cellTextStyle() {
    return const TextStyle(fontSize: 16, color: Colors.white);
  }
}

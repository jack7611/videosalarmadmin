import 'package:flutter/material.dart';
import 'package:admin/controllers/User_controller.dart';
import 'package:admin/models/User.dart';
import 'package:admin/screens/main/components/side_menu.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class UserPagesubs extends StatelessWidget {
  const UserPagesubs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserController());

    return Obx(() {
      if (userController.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      } else {
        // Filter users to only include those with active subscriptions
        final activeUsers =
            userController.users.where((user) => user.active == true).toList();

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: CustomAppBar(),
          // AppBar(
          //   title: Text('Users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          //   backgroundColor: const Color.fromARGB(255, 14, 18, 21),
          //   actions: [
          //     IconButton(
          //       icon: Icon(Icons.refresh, size: 28),
          //       onPressed: () => userController.fetchUsers(),
          //     ),
          //   ],
          // ),
          // Add SideMenu on the left side via the Drawer widget
          body: Row(
            children: [
              // Left side: SideMenu (Drawer)
              // Container(
              //   width: 250, // Fixed width for the side menu
              //   child: Drawer(
              //     child: SideMenu(),
              //   ),
              // ),
              // // Right side: User Table
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    height: double
                        .infinity, // Ensure it takes the full available height
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                            const Color.fromARGB(255, 14, 18, 21)),
                        dataRowHeight: 60, // Reduced height of rows
                        columnSpacing: 50.0, // Reduced spacing between columns
                        columns: [
                          DataColumn(
                              label: Text('Name', style: _headerTextStyle())),
                          // DataColumn(
                          //     label: Text('Email', style: _headerTextStyle())),
                          DataColumn(
                              label: Text('Status', style: _headerTextStyle())),
                          DataColumn(
                              label: Text('Expiry Date',
                                  style: _headerTextStyle())),
                          DataColumn(
                              label:
                                  Text('Plan name', style: _headerTextStyle())),
                          DataColumn(
                              label: Text('Price', style: _headerTextStyle())),
                        ],
                        rows: activeUsers.map((user) {
                          // Use activeUsers list
                          return DataRow(
                            cells: [
                              DataCell(Text(user.name ?? 'N/A',
                                  style: _cellTextStyle())),
                              // DataCell(Text(user.email ?? 'N/A',
                              //     style: _cellTextStyle())),
                              DataCell(Text(
                                  user.active ?? false ? 'Active' : 'Inactive',
                                  style: _cellTextStyle())),
                              DataCell(
                                Text(
                                  user.subscriptionExpiryDate != null
                                      ? DateFormat('MMMM d, yyyy')
                                          .format(user.subscriptionExpiryDate!)
                                      : 'N/A',
                                  style: _cellTextStyle(),
                                ),
                              ),
                              DataCell(
                                Text(
                                  user.subscriptionType == 'vip_plan_id' ||
                                          user.subscriptionType ==
                                              'com.videosalarm.subscription.premium'
                                      ? 'Premium'
                                      : 'N/A',
                                  style: _cellTextStyle(),
                                ),
                              ),
                              DataCell(
                                Text(
                                  user.subscriptionType == 'vip_plan_id' ||
                                          user.subscriptionType ==
                                              'com.videosalarm.subscription.premium'
                                      ? '₹99'
                                      : 'N/A',
                                  style: _cellTextStyle(),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
          title: Text('Edit User',
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
              child: Text('Save Changes',
                  style: TextStyle(color: Colors.deepPurple, fontSize: 18)),
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
        style: TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white, fontSize: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.deepPurple),
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
    return TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Colors.white); // Reduced header text size
  }

  TextStyle _cellTextStyle() {
    return TextStyle(
        fontSize: 16, color: Colors.white); // Reduced cell text size
  }
}

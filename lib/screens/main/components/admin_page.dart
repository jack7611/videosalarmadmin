import 'package:admin/controllers/admin_controller.dart';
import 'package:admin/controllers/creator_controller.dart';
import 'package:admin/creators/controllers/creator_sign_in_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminSignInPage extends StatefulWidget {
  const AdminSignInPage({super.key});

  @override
  State<AdminSignInPage> createState() => _AdminSignInPageState();
}

class _AdminSignInPageState extends State<AdminSignInPage> {
  bool adminLogin = true;
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminSignInController());
    final CreatorController = Get.put(CreatorSignInController());

    return Scaffold(
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: adminLogin
                  ? controller.formKey
                  : CreatorController
                      .formKey, // Attach a global key for form validation
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Section
                  Image.asset(
                    'assets/images/logo.png', // Add your logo image in assets
                    height: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    adminLogin ? 'Admin Sign in' : 'Creator Sign in',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 220, 221, 219)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            adminLogin = true;
                            setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: adminLogin
                                    ? Colors.lightBlue
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(4)),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  'Admin',
                                  style: TextStyle(
                                      color: adminLogin
                                          ? Colors.white
                                          : Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            adminLogin = false;
                            setState(() {});
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: adminLogin
                                    ? Colors.white
                                    : Colors.lightBlue,
                                borderRadius: BorderRadius.circular(4)),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  'Creator',
                                  style: TextStyle(
                                      color: adminLogin
                                          ? Colors.black
                                          : Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),

                  // Error Alert Box
                  Obx(() {
                    String error = adminLogin
                        ? controller.errorMessage.value
                        : CreatorController.errorMessage.value;
                    return error.isNotEmpty
                        ? Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.red.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 24),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    error,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 16, // Increased text size
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink();
                  }),

                  // Email Input Field
                  TextField(
                    controller: adminLogin
                        ? controller.emailController
                        : CreatorController.emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),

                  // Password Input Field
                  TextField(
                    controller: adminLogin
                        ? controller.passwordController
                        : CreatorController.passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      if (!controller.isLoading.value && adminLogin == true) {
                        controller.signIn();
                      } else if (!CreatorController.isLoading.value &&
                          adminLogin == false) {
                        CreatorController.signIn();
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Sign-In Button with Loading Indicator
                  Obx(
                    () => Container(
                      width: 150,
                      child: ElevatedButton(
                        onPressed: () {
                          if (adminLogin) {
                            controller.isLoading.value
                                ? null
                                : controller.signIn();
                          } else {
                            CreatorController.isLoading.value
                                ? null
                                : CreatorController.signIn();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                4), // Makes the button rectangular
                          ),
                        ),
                        child: 
                        controller.isLoading.value || CreatorController.isLoading.value
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Sign In'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

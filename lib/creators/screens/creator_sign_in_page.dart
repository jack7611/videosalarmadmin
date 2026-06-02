import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admin/creators/controllers/creator_sign_in_controller.dart';

class CreatorSignInPage extends StatefulWidget {
  const CreatorSignInPage({super.key});

  @override
  State<CreatorSignInPage> createState() => _CreatorSignInPageState();
}

class _CreatorSignInPageState extends State<CreatorSignInPage> {
  
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreatorSignInController());

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
              key: controller.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Section
                  Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    errorBuilder: (ctx, _, __) =>
                        const Icon(Icons.movie, size: 80, color: Colors.blue),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Creator Sign in',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  // Email Input
                  TextFormField(
                    controller: controller.emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value == null || value.isEmpty)
                        ? "Email required"
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Password Input
                  TextFormField(
                    controller: controller.passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) => (value == null || value.isEmpty)
                        ? "Password required"
                        : null,
                    onFieldSubmitted: (_) => controller.signIn(),
                  ),
                  const SizedBox(height: 20),

                  // Button
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: controller.isLoading.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Sign In'),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

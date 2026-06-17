import 'package:admin/screens/main/components/admin_page.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:get/get.dart';
import 'package:admin/creators/controllers/creator_movie_controller.dart';
import 'package:admin/creators/components/creator_movie_card.dart';
import 'package:admin/creators/screens/creator_add_movie_screen.dart';
import 'package:admin/creators/screens/creator_payment_history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatorDashboardScreen extends StatelessWidget {
  const CreatorDashboardScreen({super.key});

  void _performLogout() async {
    html.window.localStorage.remove('isCreatorLoggedIn');
    html.window.localStorage.remove('creatorId');
    html.window.localStorage.remove('creatorName');

    if (FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }

    Get.offAll(() => const AdminSignInPage());
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF321C1C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Color(0xFFFF3B30), size: 32),
              ),
              const SizedBox(height: 20),
              const Text(
                "Sign Out",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Are you sure you want to sign out of your creator account? You'll need to log in again to access the dashboard.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _performLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text("Sign Out",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = html.window.localStorage['creatorName'] ?? 'Creator';
    final CreatorMovieController controller = Get.put(CreatorMovieController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Creator Dashboard", style: TextStyle(fontSize: 32)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreatorPaymentHistoryScreen()),
              ),
              icon: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 20),
              label: const Text('My Payments',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B).withOpacity(0.85),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CreatorAddMovieScreen()),
              ),
              icon: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 20),
              label: const Text('Upload Movie',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.85),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () => _showLogoutConfirmation(context),
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              label: const Text("Logout", style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, $name!",
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text("Your Movies",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.error.isNotEmpty) {
                  return Center(
                      child: Text(controller.error.value,
                          style: const TextStyle(color: Colors.red)));
                }

                if (controller.movies.isEmpty) {
                  return const Center(child: Text("No movies assigned yet."));
                }

                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: controller.movies.length,
                  itemBuilder: (context, index) {
                    return CreatorMovieCard(movie: controller.movies[index]);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
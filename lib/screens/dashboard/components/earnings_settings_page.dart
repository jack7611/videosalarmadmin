import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EarningsSettingsPage extends StatefulWidget {
  const EarningsSettingsPage({super.key});

  @override
  State<EarningsSettingsPage> createState() => _EarningsSettingsPageState();
}

class _EarningsSettingsPageState extends State<EarningsSettingsPage> {
  final TextEditingController _rateController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadCurrentRate();
  }

  Future<void> _loadCurrentRate() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('earnings')
          .get();
      final rate = doc.data()?['ratePerWatchHour'];
      _rateController.text = rate != null ? rate.toString() : '50';
    } catch (_) {
      _rateController.text = '50';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRate() async {
    final input = _rateController.text.trim();
    final rate = double.tryParse(input);
    if (rate == null || rate <= 0) {
      setState(() => _errorText = 'Enter a valid amount greater than 0');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      // Ensure Firebase Auth is active — required by Firestore write rules.
      // This self-heals sessions restored from localStorage where signIn() was skipped.
      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance.signInAnonymously();
        } catch (_) {}
      }

      await FirebaseFirestore.instance
          .collection('settings')
          .doc('earnings')
          .set({'ratePerWatchHour': rate}, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rate saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Earnings Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.account_balance_wallet,
                                      color: Colors.white,
                                      size: 24),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'Watch Hour Rate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Set how much a creator earns per watch hour across all their movies.',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _rateController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                              decoration: InputDecoration(
                                labelText: '₹ per watch hour',
                                labelStyle: const TextStyle(
                                    color: Colors.white54),
                                prefixText: '₹  ',
                                prefixStyle: const TextStyle(
                                    color: Colors.white70, fontSize: 18),
                                errorText: _errorText,
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.15)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Colors.white54),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Colors.red),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Example: ₹50 → a creator with 10 watch hours earns ₹500',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 12),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveRate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black),
                                      )
                                    : const Text(
                                        'Save Rate',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.white38, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'View count is still tracked but earnings are based only on actual watch hours. '
                                'Watch seconds are recorded each time a user pauses or stops a video.',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12,
                                    height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

class CreatorPaymentHistoryScreen extends StatefulWidget {
  const CreatorPaymentHistoryScreen({super.key});

  @override
  State<CreatorPaymentHistoryScreen> createState() =>
      _CreatorPaymentHistoryScreenState();
}

class _CreatorPaymentHistoryScreenState
    extends State<CreatorPaymentHistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _payments = [];
  double _totalReleased = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final creatorId = html.window.localStorage['creatorId'];
      if (creatorId == null || creatorId.isEmpty) {
        setState(() {
          _error = 'Creator session not found. Please log in again.';
          _loading = false;
        });
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('creator_payments')
          .where('creatorId', isEqualTo: creatorId)
          .get();

      final payments = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        return data;
      }).toList()
        ..sort((a, b) {
          final aTs = a['releasedAt'] as Timestamp?;
          final bTs = b['releasedAt'] as Timestamp?;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });

      final total = payments.fold<double>(
          0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));

      setState(() {
        _payments = payments;
        _totalReleased = total;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Pending...';
    return DateFormat('dd MMM yyyy, hh:mm a').format(ts.toDate().toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment History',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _fetchPayments,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Color(0xFFF59E0B))))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _fetchPayments,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.black),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded,
                                  color: Color(0xFFF59E0B), size: 28),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${_totalReleased.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1),
                                ),
                                const Text(
                                  'Total Amount Released',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Text(
                                '${_payments.length} payment${_payments.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // History list
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 20, 24, 16),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.payments_rounded,
                                      color: Color(0xFFF59E0B), size: 20),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'Release History',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                ),
                              ]),
                            ),
                            if (_payments.isEmpty)
                              const Padding(
                                padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                                child: Text(
                                  'No payments have been released yet.',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 14),
                                ),
                              )
                            else
                              ...List.generate(_payments.length, (i) {
                                final p = _payments[i];
                                final amount =
                                    (p['amount'] as num?)?.toDouble() ?? 0.0;
                                final note = p['note'] as String? ?? '';
                                final ts = p['releasedAt'] as Timestamp?;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: i.isEven
                                        ? Colors.transparent
                                        : Colors.white.withOpacity(0.02),
                                    border: const Border(
                                        top: BorderSide(
                                            color: Colors.white10,
                                            width: 0.5)),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B)
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.check_rounded,
                                          color: Color(0xFFF59E0B), size: 18),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '₹${amount.toStringAsFixed(0)} released',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700),
                                          ),
                                          if (note.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(note,
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatDate(ts),
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12),
                                    ),
                                  ]),
                                );
                              }),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

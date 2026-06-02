import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({Key? key}) : super(key: key);

  @override
  _InvoiceListPageState createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  List<Invoice> invoices = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedFilter = 'All';

  // Dark theme colors
  static const Color bgPrimary = Color(0xFF0A0A0A);
  static const Color bgSecondary = Color(0xFF151515);
  static const Color bgTertiary = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFF00D9FF);
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    setState(() => isLoading = true);
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('invoices')
          .orderBy('createdAt', descending: true)
          .get();

      List<Invoice> loadedInvoices = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        loadedInvoices.add(Invoice.fromFirestore(data));
      }

      setState(() {
        invoices = loadedInvoices;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading invoices: $e');
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load invoices: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
                child:
                    Text(message, style: const TextStyle(color: textPrimary))),
          ],
        ),
        backgroundColor: const Color(0xFF2A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: accentColor),
            const SizedBox(width: 12),
            Expanded(
                child:
                    Text(message, style: const TextStyle(color: textPrimary))),
          ],
        ),
        backgroundColor: bgTertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<Invoice> get filteredInvoices {
    return invoices.where((invoice) {
      final matchesSearch = invoice.invoiceNumber
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          invoice.userName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          invoice.userPhone.contains(searchQuery);

      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgSecondary,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgTertiary,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: accentColor.withOpacity(0.3), width: 1),
              ),
              child:
                  const Icon(Icons.receipt_long, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Invoice Management',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: bgTertiary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  '${filteredInvoices.length} Invoices',
                  style: const TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: textPrimary),
            onPressed: () {
              loadInvoices();
              _showSuccessSnackBar('Invoices refreshed');
            },
            tooltip: 'Refresh Invoices',
            splashRadius: 24,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header Section with Search
          Container(
            color: bgSecondary,
            padding: EdgeInsets.all(isWideScreen ? 24 : 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: TextField(
                          style: const TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            hintText:
                                'Search by invoice number, name, or phone...',
                            hintStyle: const TextStyle(color: textSecondary),
                            prefixIcon:
                                const Icon(Icons.search, color: accentColor),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        size: 20, color: textSecondary),
                                    onPressed: () {
                                      setState(() {
                                        searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: bgTertiary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: accentColor.withOpacity(0.3),
                                  width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: accentColor.withOpacity(0.2),
                                  width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: accentColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: bgTertiary),

          // Content Area
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Loading invoices...',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredInvoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: bgTertiary),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No invoices found'
                                  : 'No matching invoices',
                              style: const TextStyle(
                                color: textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchQuery.isEmpty
                                  ? 'Invoices will appear here once created'
                                  : 'Try a different search term',
                              style: TextStyle(
                                color: textSecondary.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : buildInvoiceCards(isWideScreen),
          ),
        ],
      ),
    );
  }

  Widget buildInvoiceCards(bool isWideScreen) {
    return ListView.builder(
      padding: EdgeInsets.all(isWideScreen ? 24 : 16),
      itemCount: filteredInvoices.length,
      itemBuilder: (context, index) {
        final invoice = filteredInvoices[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bgTertiary, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {},
            hoverColor: bgTertiary.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: isWideScreen
                  ? _buildWideScreenLayout(invoice)
                  : _buildCompactLayout(invoice),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideScreenLayout(Invoice invoice) {
    return Row(
      children: [
        // Invoice Number Section
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invoice Number',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                invoice.invoiceNumber,
                style: const TextStyle(
                  color: accentColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        // User Info Section
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                invoice.userName,
                style: const TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 14, color: textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    invoice.userPhone,
                    style: const TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Date Section
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Created Date',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    invoice.createdAtFormatted,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Action Button
        ElevatedButton.icon(
          onPressed: () async {
            if (await canLaunchUrl(Uri.parse(invoice.downloadUrl))) {
              await launchUrl(Uri.parse(invoice.downloadUrl));
              _showSuccessSnackBar('Opening invoice download...');
            } else {
              _showErrorSnackBar('Could not launch download URL');
            }
          },
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Download'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(Invoice invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                      color: accentColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    invoice.userName,
                    style: const TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (await canLaunchUrl(Uri.parse(invoice.downloadUrl))) {
                  await launchUrl(Uri.parse(invoice.downloadUrl));
                  _showSuccessSnackBar('Opening invoice download...');
                } else {
                  _showErrorSnackBar('Could not launch download URL');
                }
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Divider(color: bgTertiary, height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.phone_outlined, size: 14, color: textSecondary),
            const SizedBox(width: 6),
            Text(
              invoice.userPhone,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: textSecondary),
            const SizedBox(width: 6),
            Text(
              invoice.createdAtFormatted,
              style: const TextStyle(
                color: textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class Invoice {
  final String invoiceNumber;
  final String downloadUrl;
  final String userId;
  final String userName;
  final String userPhone;
  final DateTime createdAt;
  final DateTime? subscriptionPurchaseDate;
  final DateTime? subscriptionExpiryDate;
  final String subscriptionType;
  final String price;

  Invoice({
    required this.invoiceNumber,
    required this.downloadUrl,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.createdAt,
    this.subscriptionPurchaseDate,
    this.subscriptionExpiryDate,
    required this.subscriptionType,
    required this.price,
  });

  String get createdAtFormatted =>
      DateFormat('yyyy-MM-dd HH:mm').format(createdAt);
  String get subscriptionPurchaseDateFormatted =>
      subscriptionPurchaseDate != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(subscriptionPurchaseDate!)
          : 'N/A';
  String get subscriptionExpiryDateFormatted => subscriptionExpiryDate != null
      ? DateFormat('yyyy-MM-dd HH:mm').format(subscriptionExpiryDate!)
      : 'N/A';

  factory Invoice.fromFirestore(Map<String, dynamic> data) {
    String price = 'N/A';
    String subscriptionType = 'N/A';
    return Invoice(
        invoiceNumber: data['invoiceNumber'] ?? '',
        downloadUrl: data['downloadUrl'] ?? '',
        userId: data['userId'] ?? '',
        userName: data['userName'] ?? '',
        userPhone: data['userPhone'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        subscriptionPurchaseDate:
            data.containsKey('subscriptionPurchaseDate') &&
                    data['subscriptionPurchaseDate'] != null
                ? (data['subscriptionPurchaseDate'] as Timestamp).toDate()
                : null,
        subscriptionExpiryDate: data.containsKey('subscriptionExpiryDate') &&
                data['subscriptionExpiryDate'] != null
            ? (data['subscriptionExpiryDate'] as Timestamp).toDate()
            : null,
        subscriptionType: data['subscriptionType'] ?? '',
        price: data['price'] ?? '');
  }
}

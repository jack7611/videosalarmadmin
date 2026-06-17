import 'dart:io';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

  DateTime? _filterFromDate;
  DateTime? _filterToDate;

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

  // ── PDF generation ────────────────────────────────────────────────────────

  Future<void> _downloadInvoicePdf(Invoice invoice) async {
    try {
      final pdfBytes = await _buildInvoicePdf(invoice);
      final fileName = 'Invoice_${invoice.invoiceNumber}.pdf';

      // On web: trigger browser download directly
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);

      _showSuccessSnackBar('Invoice downloaded: $fileName');
    } catch (e) {
      _showErrorSnackBar('Failed to generate PDF: $e');
    }
  }

  Future<List<int>> _buildInvoicePdf(Invoice invoice) async {
    final doc = pw.Document();

    // Load logo from assets
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    final totalAmount =
        double.tryParse(invoice.price.replaceAll('₹', '').replaceAll('Rs.', '').trim()) ?? 0.0;
    final baseAmount = totalAmount / 1.18;
    final gstAmount = totalAmount - baseAmount;

    // Note: PDF default fonts don't support ₹ unicode — using "Rs." instead
    String rs(double v) => 'Rs. ${v.toStringAsFixed(2)}';

    final dateFormat = DateFormat('dd/MM/yyyy');
    final invoiceDate = dateFormat.format(invoice.createdAt);
    final purchaseDate = invoice.subscriptionPurchaseDate != null
        ? dateFormat.format(invoice.subscriptionPurchaseDate!)
        : 'N/A';
    final expiryDate = invoice.subscriptionExpiryDate != null
        ? dateFormat.format(invoice.subscriptionExpiryDate!)
        : 'N/A';

    final planName = (invoice.subscriptionType == 'basic_plan_id' ||
            invoice.subscriptionType.isEmpty)
        ? 'Basic Plan'
        : 'Premium Plan';

    const headerBg = PdfColor.fromInt(0xFF1A237E);   // deep indigo
    const accentPdf = PdfColor.fromInt(0xFF3F51B5);  // indigo
    const lightBg   = PdfColor.fromInt(0xFFF3F4FF);  // very light indigo tint
    const darkText  = PdfColor.fromInt(0xFF1A1A2E);
    const mutedText = PdfColor.fromInt(0xFF6B7280);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              // ── TOP HEADER BAR ────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                decoration: const pw.BoxDecoration(
                  color: headerBg,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Logo + brand name
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoImage != null) ...[
                          pw.Container(
                            width: 52,
                            height: 52,
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius:
                                  pw.BorderRadius.all(pw.Radius.circular(8)),
                            ),
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                          pw.SizedBox(width: 14),
                        ],
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Videos Alarm',
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              'www.videosalarm.com',
                              style: const pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColor.fromInt(0xFFB3C5FF)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // TAX INVOICE + number + date
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          '# ${invoice.invoiceNumber}',
                          style: const pw.TextStyle(
                              fontSize: 14,
                              color: PdfColor.fromInt(0xFFB3C5FF)),
                        ),
                        pw.Text(
                          'Date: $invoiceDate',
                          style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColor.fromInt(0xFFB3C5FF)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // ── FROM / BILL TO cards ──────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // FROM
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: const pw.BoxDecoration(
                        color: lightBg,
                        borderRadius:
                            pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('FROM',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: accentPdf,
                                  letterSpacing: 1.5)),
                          pw.SizedBox(height: 6),
                          pw.Text('Videos Alarm',
                              style: pw.TextStyle(
                                  fontSize: 15,
                                  fontWeight: pw.FontWeight.bold,
                                  color: darkText)),
                          pw.SizedBox(height: 4),
                          pw.Text(
                              'Shree Palace, 11 Ananya Vihar,',
                              style: pw.TextStyle(
                                  fontSize: 11, color: mutedText)),
                          pw.Text(
                              'Adj Doon South Apartments, Sewla Chowk',
                              style: pw.TextStyle(
                                  fontSize: 11, color: mutedText)),
                          pw.Text(
                              'GMS Road, Dehradun, Uttarakhand - India',
                              style: pw.TextStyle(
                                  fontSize: 11, color: mutedText)),
                          pw.Text('info@videosalarm.com',
                              style: pw.TextStyle(
                                  fontSize: 11, color: mutedText)),
                          pw.SizedBox(height: 6),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: accentPdf,
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              'GSTIN: 05AADCC3324K1ZX',
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.white),
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('SAC Code: 998431',
                              style: pw.TextStyle(
                                  fontSize: 11, color: mutedText)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // BILL TO
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.grey300, width: 1),
                        borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: accentPdf,
                                  letterSpacing: 1.5)),
                          pw.SizedBox(height: 6),
                          pw.Text(invoice.userName,
                              style: pw.TextStyle(
                                  fontSize: 15,
                                  fontWeight: pw.FontWeight.bold,
                                  color: darkText)),
                          pw.SizedBox(height: 4),
                          if (invoice.userPhone.isNotEmpty)
                            pw.Text('Phone: ${invoice.userPhone}',
                                style: pw.TextStyle(
                                    fontSize: 11, color: mutedText)),
                          if (purchaseDate != 'N/A')
                            pw.Text('Purchase Date: $purchaseDate',
                                style: pw.TextStyle(
                                    fontSize: 11, color: mutedText)),
                          if (expiryDate != 'N/A')
                            pw.Text('Valid Until: $expiryDate',
                                style: pw.TextStyle(
                                    fontSize: 11, color: mutedText)),
                          pw.SizedBox(height: 8),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: totalAmount > 0
                                  ? const PdfColor.fromInt(0xFFE8F5E9)
                                  : PdfColors.grey200,
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              totalAmount > 0 ? 'PAID' : 'FREE PLAN',
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: totalAmount > 0
                                    ? const PdfColor.fromInt(0xFF2E7D32)
                                    : mutedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // ── Line items table ──────────────────────────────────────
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(5),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: headerBg),
                    children: [
                      _cell('Description',
                          bold: true, textColor: PdfColors.white),
                      _cell('Plan',
                          bold: true, textColor: PdfColors.white),
                      _cell('Amount (excl. GST)',
                          bold: true,
                          align: pw.TextAlign.right,
                          textColor: PdfColors.white),
                    ],
                  ),
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.white),
                    children: [
                      _cell('$planName Subscription\n(SAC: 998431 - Online Content Streaming)'),
                      _cell(planName),
                      _cell(rs(baseAmount), align: pw.TextAlign.right),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ── GST summary ───────────────────────────────────────────
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 280,
                  decoration: const pw.BoxDecoration(
                    color: lightBg,
                    borderRadius:
                        pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  padding: const pw.EdgeInsets.all(14),
                  child: pw.Column(children: [
                    _summaryRow('Subtotal (excl. GST)', rs(baseAmount),
                        mutedText: mutedText),
                    _summaryRow('CGST @ 9%',
                        rs(gstAmount / 2), mutedText: mutedText),
                    _summaryRow('SGST @ 9%',
                        rs(gstAmount / 2), mutedText: mutedText),
                    pw.Container(
                        height: 1,
                        color: PdfColors.grey300,
                        margin: const pw.EdgeInsets.symmetric(vertical: 6)),
                    _summaryRow('Total Amount', rs(totalAmount),
                        bold: true, fontSize: 14, textColor: darkText),
                  ]),
                ),
              ),
              pw.SizedBox(height: 20),

              // ── Validity banner ───────────────────────────────────────
              if (purchaseDate != 'N/A' && expiryDate != 'N/A')
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFE8EAF6),
                    borderRadius:
                        pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text('Subscription Period: ',
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: darkText)),
                      pw.Text('$purchaseDate   to   $expiryDate',
                          style: pw.TextStyle(
                              fontSize: 12, color: accentPdf)),
                    ],
                  ),
                ),

              pw.Spacer(),

              // ── Footer ────────────────────────────────────────────────
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: const pw.BoxDecoration(
                  color: lightBg,
                  borderRadius:
                      pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Thank you for subscribing to Videos Alarm!',
                      style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: accentPdf),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'This is a computer-generated invoice. No signature required.',
                      style: const pw.TextStyle(
                          fontSize: 10, color: mutedText),
                    ),
                    pw.Text(
                      'Support: info@videosalarm.com  |  www.videosalarm.com',
                      style: const pw.TextStyle(
                          fontSize: 10, color: mutedText),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _cell(String text,
      {bool bold = false,
      pw.TextAlign align = pw.TextAlign.left,
      PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
          fontSize: 11,
        ),
      ),
    );
  }

  pw.Widget _summaryRow(String label, String value,
      {bool bold = false,
      double fontSize = 12,
      PdfColor? mutedText,
      PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: fontSize,
                color: textColor ?? mutedText,
              )),
          pw.Text(value,
              style: pw.TextStyle(
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                fontSize: fontSize,
                color: textColor,
              )),
        ],
      ),
    );
  }

  // ── Snackbars ─────────────────────────────────────────────────────────────

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

  Future<void> _exportAllSubscribersToExcel() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        content: Row(
          children: [
            CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF))),
            SizedBox(width: 20),
            Text('Preparing invoices for all subscribers...',
                style: TextStyle(color: Color(0xFFE8E8E8))),
          ],
        ),
      ),
    );

    try {
      // Step 1: Freshly fetch ALL invoices to build lookup maps + find max invoice number
      final QuerySnapshot invoiceSnapshot =
          await FirebaseFirestore.instance.collection('invoices').get();

      final Map<String, String> invoiceByUserId = {};
      final Map<String, String> invoiceByPhone = {};
      int maxInvoiceNum = 10000;

      for (var doc in invoiceSnapshot.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final String invNum = d['invoiceNumber'] as String? ?? '';
        if (invNum.isEmpty) continue;
        final String uid = d['userId'] as String? ?? '';
        final String phone = d['userPhone'] as String? ?? '';
        if (uid.isNotEmpty) invoiceByUserId[uid] = invNum;
        if (phone.isNotEmpty) invoiceByPhone[phone] = invNum;
        // Track max invoice number to continue sequence
        if (invNum.startsWith('VAI')) {
          final numPart = int.tryParse(invNum.substring(3));
          if (numPart != null && numPart > maxInvoiceNum) {
            maxInvoiceNum = numPart;
          }
        }
      }

      // Step 2: Fetch ALL users with a paid subscription
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> subscriberRows = [];
      final dateFormat = DateFormat('dd/MM/yyyy');

      // Collect users that need a new invoice number generated
      final List<Map<String, dynamic>> needsInvoice = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String subType = data['SubscriptionType'] as String? ?? '';
        final bool isActive = data['Active'] as bool? ?? false;
        final bool isDeleted = data['isDeleted'] as bool? ?? false;

        final bool hasPaidSub =
            subType.isNotEmpty && subType != 'basic_plan_id';

        if (isDeleted || (!hasPaidSub && !isActive)) continue;

        DateTime? purchaseDate;
        DateTime? expiryDate;
        if (data['SubscriptionStartDate'] != null) {
          purchaseDate = (data['SubscriptionStartDate'] as Timestamp).toDate();
        }
        if (data['SubscriptionExpiryDate'] != null) {
          expiryDate = (data['SubscriptionExpiryDate'] as Timestamp).toDate();
        }

        String planName = 'Premium';
        String price = '₹99';
        if (subType == 'basic_plan_id' || subType.isEmpty) {
          planName = 'Basic';
          price = '₹0';
        }

        String status = 'Unknown';
        if (expiryDate != null) {
          status = expiryDate.isAfter(DateTime.now()) ? 'Active' : 'Expired';
        } else if (isActive) {
          status = 'Active';
        }

        final String userPhone = data['phone'] as String? ?? '';
        final String existingInvoice = invoiceByUserId[doc.id] ??
            (userPhone.isNotEmpty ? invoiceByPhone[userPhone] : null) ??
            '';

        subscriberRows.add({
          'invoiceNumber': existingInvoice,
          'name': data['name'] as String? ?? 'N/A',
          'phone': userPhone.isNotEmpty ? userPhone : 'N/A',
          'email': data['email'] as String? ?? 'N/A',
          'plan': planName,
          'price': price,
          'purchaseDate':
              purchaseDate != null ? dateFormat.format(purchaseDate) : 'N/A',
          'expiryDate':
              expiryDate != null ? dateFormat.format(expiryDate) : 'N/A',
          'status': status,
          'paymentMethod': data['paymentMethod'] as String? ?? 'N/A',
          'purchaseToken': data['PurchaseToken'] as String? ?? 'N/A',
          'userId': doc.id,
          'purchaseDateRaw': purchaseDate,
          'expiryDateRaw': expiryDate,
          'subType': subType,
        });

        if (existingInvoice.isEmpty) {
          needsInvoice.add(subscriberRows.last);
        }
      }

      // Step 3: Generate invoice numbers for subscribers who don't have one
      // and save them to Firestore so they are permanent
      if (needsInvoice.isNotEmpty) {
        const int batchLimit = 499;
        int batchCount = 0;
        WriteBatch batch = FirebaseFirestore.instance.batch();

        for (var row in needsInvoice) {
          maxInvoiceNum++;
          final String newInvoice =
              'VAI${maxInvoiceNum.toString().padLeft(5, '0')}';
          row['invoiceNumber'] = newInvoice;

          final docRef =
              FirebaseFirestore.instance.collection('invoices').doc();
          batch.set(docRef, {
            'invoiceNumber': newInvoice,
            'downloadUrl': '',
            'userId': row['userId'],
            'userName': row['name'],
            'userPhone': row['phone'] == 'N/A' ? '' : row['phone'],
            'createdAt': Timestamp.now(),
            'subscriptionPurchaseDate': row['purchaseDateRaw'] != null
                ? Timestamp.fromDate(row['purchaseDateRaw'] as DateTime)
                : null,
            'subscriptionExpiryDate': row['expiryDateRaw'] != null
                ? Timestamp.fromDate(row['expiryDateRaw'] as DateTime)
                : null,
            'subscriptionType': row['subType'],
            'price': row['price'],
          });

          batchCount++;
          if (batchCount >= batchLimit) {
            await batch.commit();
            batch = FirebaseFirestore.instance.batch();
            batchCount = 0;
          }
        }
        if (batchCount > 0) await batch.commit();
      }

      // Step 4: Sort by purchase date and build Excel
      subscriberRows.sort((a, b) {
        final aDate = a['purchaseDateRaw'] as DateTime?;
        final bDate = b['purchaseDateRaw'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      final excel = Excel.createExcel();
      final Sheet sheet = excel['All Subscribers'];

      sheet.appendRow([
        'Sr No',
        'Invoice Number',
        'Customer Name',
        'Phone',
        'Email',
        'Plan',
        'Amount',
        'Purchase Date',
        'Expiry Date',
        'Status',
        'Payment Method',
        'Purchase Token',
        'User ID',
      ].map((h) => TextCellValue(h)).toList());

      int srNo = 1;
      for (var row in subscriberRows) {
        sheet.appendRow([
          TextCellValue(srNo.toString()),
          TextCellValue(row['invoiceNumber']),
          TextCellValue(row['name']),
          TextCellValue(row['phone']),
          TextCellValue(row['email']),
          TextCellValue(row['plan']),
          TextCellValue(row['price']),
          TextCellValue(row['purchaseDate']),
          TextCellValue(row['expiryDate']),
          TextCellValue(row['status']),
          TextCellValue(row['paymentMethod']),
          TextCellValue(row['purchaseToken']),
          TextCellValue(row['userId']),
        ]);
        srNo++;
      }

      Navigator.of(context).pop();

      final String fileName =
          'All_Subscribers_Invoice_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      final fileBytes = excel.save();

      if (fileBytes == null) {
        _showErrorSnackBar('Failed to generate Excel file.');
        return;
      }

      if (kIsWeb) {
        excel.save(fileName: fileName);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(fileBytes, flush: true);
      }

      final int newlyGenerated = needsInvoice.length;
      _showSuccessSnackBar(
          'Exported ${subscriberRows.length} subscribers. '
          '${newlyGenerated > 0 ? '$newlyGenerated new invoice numbers generated.' : 'All invoice numbers already existed.'}');

      // Reload invoice list to show newly created invoices
      if (newlyGenerated > 0) loadInvoices();
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Error exporting Excel: $e');
    }
  }

  Future<void> _pickDateRangeAndExport() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: (_filterFromDate != null && _filterToDate != null)
          ? DateTimeRange(start: _filterFromDate!, end: _filterToDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: accentColor,
            onPrimary: Colors.black,
            surface: Color(0xFF1E1E1E),
            onSurface: textPrimary,
          ),
          dialogBackgroundColor: bgSecondary,
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    setState(() {
      _filterFromDate = picked.start;
      _filterToDate = DateTime(
          picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
    });

    await _exportByDateRangeToExcel(_filterFromDate!, _filterToDate!);
  }

  Future<void> _exportByDateRangeToExcel(
      DateTime fromDate, DateTime toDate) async {
    final dateLabel =
        '${DateFormat('dd-MMM-yyyy').format(fromDate)}_to_${DateFormat('dd-MMM-yyyy').format(toDate)}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Row(
          children: [
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor)),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                'Exporting invoices from ${DateFormat('dd MMM yyyy').format(fromDate)} to ${DateFormat('dd MMM yyyy').format(toDate)}...',
                style: const TextStyle(color: textPrimary),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Fetch invoice lookup maps (same as full export)
      final QuerySnapshot invoiceSnapshot =
          await FirebaseFirestore.instance.collection('invoices').get();

      final Map<String, String> invoiceByUserId = {};
      final Map<String, String> invoiceByPhone = {};
      int maxInvoiceNum = 10000;

      for (var doc in invoiceSnapshot.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final String invNum = d['invoiceNumber'] as String? ?? '';
        if (invNum.isEmpty) continue;
        final String uid = d['userId'] as String? ?? '';
        final String phone = d['userPhone'] as String? ?? '';
        if (uid.isNotEmpty) invoiceByUserId[uid] = invNum;
        if (phone.isNotEmpty) invoiceByPhone[phone] = invNum;
        if (invNum.startsWith('VAI')) {
          final numPart = int.tryParse(invNum.substring(3));
          if (numPart != null && numPart > maxInvoiceNum) {
            maxInvoiceNum = numPart;
          }
        }
      }

      // Fetch all users and filter by purchase date range
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<Map<String, dynamic>> subscriberRows = [];
      final List<Map<String, dynamic>> needsInvoice = [];
      final dateFormat = DateFormat('dd/MM/yyyy');

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final bool isDeleted = data['isDeleted'] as bool? ?? false;
        if (isDeleted) continue;

        final String subType = data['SubscriptionType'] as String? ?? '';
        final bool isActive = data['Active'] as bool? ?? false;
        final bool hasPaidSub =
            subType.isNotEmpty && subType != 'basic_plan_id';
        if (!hasPaidSub && !isActive) continue;

        DateTime? purchaseDate;
        DateTime? expiryDate;
        if (data['SubscriptionStartDate'] != null) {
          purchaseDate = (data['SubscriptionStartDate'] as Timestamp).toDate();
        }
        if (data['SubscriptionExpiryDate'] != null) {
          expiryDate = (data['SubscriptionExpiryDate'] as Timestamp).toDate();
        }

        // ── DATE RANGE FILTER ──
        if (purchaseDate == null) continue;
        if (purchaseDate.isBefore(fromDate) || purchaseDate.isAfter(toDate)) {
          continue;
        }

        String planName =
            (subType == 'basic_plan_id' || subType.isEmpty) ? 'Basic' : 'Premium';
        String price =
            (subType == 'basic_plan_id' || subType.isEmpty) ? '₹0' : '₹99';

        String status = 'Unknown';
        if (expiryDate != null) {
          status = expiryDate.isAfter(DateTime.now()) ? 'Active' : 'Expired';
        } else if (isActive) {
          status = 'Active';
        }

        final String userPhone = data['phone'] as String? ?? '';
        final String existingInvoice = invoiceByUserId[doc.id] ??
            (userPhone.isNotEmpty ? invoiceByPhone[userPhone] : null) ??
            '';

        subscriberRows.add({
          'invoiceNumber': existingInvoice,
          'name': data['name'] as String? ?? 'N/A',
          'phone': userPhone.isNotEmpty ? userPhone : 'N/A',
          'email': data['email'] as String? ?? 'N/A',
          'plan': planName,
          'price': price,
          'purchaseDate':
              purchaseDate != null ? dateFormat.format(purchaseDate) : 'N/A',
          'expiryDate':
              expiryDate != null ? dateFormat.format(expiryDate) : 'N/A',
          'status': status,
          'paymentMethod': data['paymentMethod'] as String? ?? 'N/A',
          'purchaseToken': data['PurchaseToken'] as String? ?? 'N/A',
          'userId': doc.id,
          'purchaseDateRaw': purchaseDate,
          'expiryDateRaw': expiryDate,
          'subType': subType,
        });

        if (existingInvoice.isEmpty) needsInvoice.add(subscriberRows.last);
      }

      // Generate new invoice numbers if needed
      if (needsInvoice.isNotEmpty) {
        const int batchLimit = 499;
        int batchCount = 0;
        WriteBatch batch = FirebaseFirestore.instance.batch();

        for (var row in needsInvoice) {
          maxInvoiceNum++;
          final String newInvoice =
              'VAI${maxInvoiceNum.toString().padLeft(5, '0')}';
          row['invoiceNumber'] = newInvoice;

          final docRef =
              FirebaseFirestore.instance.collection('invoices').doc();
          batch.set(docRef, {
            'invoiceNumber': newInvoice,
            'downloadUrl': '',
            'userId': row['userId'],
            'userName': row['name'],
            'userPhone': row['phone'] == 'N/A' ? '' : row['phone'],
            'createdAt': Timestamp.now(),
            'subscriptionPurchaseDate': row['purchaseDateRaw'] != null
                ? Timestamp.fromDate(row['purchaseDateRaw'] as DateTime)
                : null,
            'subscriptionExpiryDate': row['expiryDateRaw'] != null
                ? Timestamp.fromDate(row['expiryDateRaw'] as DateTime)
                : null,
            'subscriptionType': row['subType'],
            'price': row['price'],
          });

          batchCount++;
          if (batchCount >= batchLimit) {
            await batch.commit();
            batch = FirebaseFirestore.instance.batch();
            batchCount = 0;
          }
        }
        if (batchCount > 0) await batch.commit();
      }

      // Sort by purchase date
      subscriberRows.sort((a, b) {
        final aDate = a['purchaseDateRaw'] as DateTime?;
        final bDate = b['purchaseDateRaw'] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      Navigator.of(context).pop();

      if (subscriberRows.isEmpty) {
        _showErrorSnackBar(
            'No subscribers found for the selected date range ($dateLabel).');
        return;
      }

      // Build Excel
      final excel = Excel.createExcel();
      final Sheet sheet = excel['Subscribers_$dateLabel'];

      // Title row
      sheet.appendRow([
        TextCellValue(
            'Invoices: ${DateFormat('dd MMM yyyy').format(fromDate)} → ${DateFormat('dd MMM yyyy').format(toDate)}'),
      ]);
      sheet.appendRow([TextCellValue('')]);

      sheet.appendRow([
        'Sr No',
        'Invoice Number',
        'Customer Name',
        'Phone',
        'Email',
        'Plan',
        'Amount',
        'Purchase Date',
        'Expiry Date',
        'Status',
        'Payment Method',
        'Purchase Token',
        'User ID',
      ].map((h) => TextCellValue(h)).toList());

      int srNo = 1;
      for (var row in subscriberRows) {
        sheet.appendRow([
          TextCellValue(srNo.toString()),
          TextCellValue(row['invoiceNumber']),
          TextCellValue(row['name']),
          TextCellValue(row['phone']),
          TextCellValue(row['email']),
          TextCellValue(row['plan']),
          TextCellValue(row['price']),
          TextCellValue(row['purchaseDate']),
          TextCellValue(row['expiryDate']),
          TextCellValue(row['status']),
          TextCellValue(row['paymentMethod']),
          TextCellValue(row['purchaseToken']),
          TextCellValue(row['userId']),
        ]);
        srNo++;
      }

      final String fileName =
          'Invoices_${dateLabel}_${DateFormat('HHmm').format(DateTime.now())}.xlsx';
      final fileBytes = excel.save();

      if (fileBytes == null) {
        _showErrorSnackBar('Failed to generate Excel file.');
        return;
      }

      if (kIsWeb) {
        excel.save(fileName: fileName);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(fileBytes, flush: true);
      }

      _showSuccessSnackBar(
          'Exported ${subscriberRows.length} subscribers for $dateLabel.');

      if (needsInvoice.isNotEmpty) loadInvoices();
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Error exporting Excel: $e');
    }
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _pickDateRangeAndExport,
              icon: const Icon(Icons.date_range_rounded, size: 18),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Export by Date',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (_filterFromDate != null && _filterToDate != null)
                    Text(
                      '${DateFormat('dd MMM').format(_filterFromDate!)} – ${DateFormat('dd MMM yyyy').format(_filterToDate!)}',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.7)),
                    ),
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A6B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _exportAllSubscribersToExcel,
              icon: const Icon(Icons.table_chart_rounded, size: 18),
              label: const Text('Export All to Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E6B3C),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
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
          onPressed: () => _downloadInvoicePdf(invoice),
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
              onPressed: () => _downloadInvoicePdf(invoice),
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

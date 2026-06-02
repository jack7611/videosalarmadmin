// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:excel/excel.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:url_launcher/url_launcher.dart';

// class SubscriptionTrackerPage extends StatefulWidget {
//   const SubscriptionTrackerPage({Key? key}) : super(key: key);

//   @override
//   State<SubscriptionTrackerPage> createState() =>
//       _SubscriptionTrackerPageState();
// }

// class _SubscriptionTrackerPageState extends State<SubscriptionTrackerPage>
//     with TickerProviderStateMixin {
//   List<UserSubscription> subscriptions = [];
//   bool isLoading = true;
//   String searchQuery = '';
//   String statusFilter = 'All';
//   String backendStatusFilter = 'All';
//   String paymentMethodFilter = 'All';
//   bool isGridView = false;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   DateTimeRange? selectedDateRange;
//   bool isDateFilterActive = false;

//   final List<String> statusOptions = [
//     'All',
//     'Success',
//     'Failed',
//     'Aborted',
//     'Cancelled',
//     'Pending'
//   ];
//   final List<String> backendStatusOptions = [
//     'All',
//     'Active',
//     'Unknown',
//     'Expired'
//   ];
//   final List<String> paymentMethodOptions = [
//     'All',
//     'iOS',
//     'Android',
//     'Razorpay'
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeInOut,
//       ),
//     );
//     loadSubscriptions();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> loadSubscriptions() async {
//     setState(() => isLoading = true);
//     try {
//       final QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('subscription')
//           .orderBy('updatedAt', descending: true)
//           .get();
//       List<UserSubscription> loadedSubscriptions = [];

//       for (var doc in snapshot.docs) {
//         final data = doc.data() as Map<String, dynamic>;

//         final bool isTestRecord = data['test'] ?? false;

//         if (isTestRecord) {
//           continue;
//         }

//         final subscription =
//             UserSubscription.fromSubscriptionCollection(doc.id, data);
//         loadedSubscriptions.add(subscription);
//       }

//       setState(() {
//         subscriptions = loadedSubscriptions;
//         isLoading = false;
//       });
//       _animationController.forward();
//     } catch (e) {
//       print('Error loading subscriptions: $e');
//       setState(() => isLoading = false);
//       _showErrorSnackBar(
//           'Failed to load subscriptions: $e. You may need to create a composite index in Firestore.');
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error_outline, color: Colors.white),
//             const SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.red.shade600,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle_outline, color: Colors.white),
//             const SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.green.shade600,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }

//   void _showInvoiceDownloadDialog(String userName, String downloadUrl) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF2A2A2A),
//         title: Row(
//           children: [
//             Icon(Icons.receipt_long, color: Colors.green.shade400),
//             const SizedBox(width: 10),
//             const Text(
//               'Invoice Available',
//               style: TextStyle(color: Colors.white),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'An invoice has been found for $userName.',
//               style: const TextStyle(color: Colors.white70),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () async {
//                       Navigator.of(context).pop();
//                       // Launch the download URL.  Consider using url_launcher package for a more robust solution.
//                       if (await canLaunchUrl(Uri.parse(downloadUrl))) {
//                         await launchUrl(Uri.parse(downloadUrl));
//                       } else {
//                         _showErrorSnackBar(
//                             'Could not launch invoice URL.  Ensure url_launcher package is added, and check url is correct');
//                       }
//                     },
//                     icon: const Icon(Icons.download),
//                     label: const Text('Download'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue.shade600,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                     icon: const Icon(Icons.close),
//                     label: const Text('Close'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey.shade600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<Uint8List> _createInvoicePdf(
//       UserSubscription subscription, String invoiceNumber) async {
//     final pdf = pw.Document();

//     final double totalAmount =
//         double.tryParse(subscription.price.replaceAll('₹', '').trim()) ?? 0.0;
//     final double baseAmount = totalAmount / 1.18;
//     final double gstAmount = totalAmount - baseAmount;

//     final formattedBaseAmount = '${baseAmount.toStringAsFixed(2)}';
//     final formattedGstAmount = '${gstAmount.toStringAsFixed(2)}';
//     final formattedTotalAmount = '${totalAmount.toStringAsFixed(2)}';

//     String displayPaymentMethod;
//     switch (subscription.paymentMethod.toLowerCase()) {
//       case 'android':
//         displayPaymentMethod = 'Google Play Store';
//         break;
//       case 'ios':
//         displayPaymentMethod = 'Apple Store';
//         break;
//       case 'razorpay':
//         displayPaymentMethod = 'Razorpay';
//         break;
//       default:
//         displayPaymentMethod = subscription.paymentMethod;
//     }

//     final customPageFormat = PdfPageFormat(
//       (595 + 842) / 2,
//       (842 + 1191) / 2,
//     );

//     pdf.addPage(
//       pw.Page(
//         pageFormat: customPageFormat,
//         build: (pw.Context context) {
//           return pw.Padding(
//             padding:
//                 const pw.EdgeInsets.symmetric(horizontal: 42, vertical: 50),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Container(
//                   width: double.infinity,
//                   padding: const pw.EdgeInsets.symmetric(
//                       horizontal: 16, vertical: 20),
//                   decoration: pw.BoxDecoration(
//                     color: PdfColors.blue900,
//                     borderRadius:
//                         const pw.BorderRadius.all(pw.Radius.circular(10)),
//                   ),
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.start,
//                     children: [
//                       pw.Row(
//                         mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                         children: [
//                           pw.Text(
//                             'SUBSCRIPTION INVOICE',
//                             style: pw.TextStyle(
//                               fontSize: 28,
//                               wordSpacing: 2,
//                               fontWeight: pw.FontWeight.bold,
//                               color: PdfColors.white,
//                             ),
//                           ),
//                         ],
//                       ),
//                       pw.SizedBox(height: 10),
//                       pw.Text(
//                         'Invoice Number: $invoiceNumber',
//                         style: const pw.TextStyle(
//                           fontSize: 14,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                       pw.SizedBox(height: 7),
//                       pw.Text(
//                         'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
//                         style: const pw.TextStyle(
//                           fontSize: 14,
//                           color: PdfColors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 pw.SizedBox(height: 30),
//                 pw.Row(
//                   mainAxisSize: pw.MainAxisSize.max,
//                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Expanded(
//                       child: pw.Padding(
//                         padding: const pw.EdgeInsets.only(left: 8),
//                         child: pw.Column(
//                           crossAxisAlignment: pw.CrossAxisAlignment.start,
//                           children: [
//                             pw.Text(
//                               'FROM:',
//                               style: pw.TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: pw.FontWeight.bold,
//                                 color: PdfColors.grey600,
//                               ),
//                             ),
//                             pw.SizedBox(height: 5),
//                             pw.Text(
//                               'Videos Alarm',
//                               style: pw.TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: pw.FontWeight.bold,
//                               ),
//                             ),
//                             pw.Text(
//                                 'Shree Palace, 11 Ananya Vihar,\nAdj Doon South Apartments, Sewla Chowk'),
//                             pw.Text('GMS Road, Dehradun, Uttarakhand, India'),
//                             pw.Text('Email: info@videosalarm.com'),
//                             pw.Text('GSTIN: 05AADCC3324K1ZX'),
//                             pw.SizedBox(height: 5),
//                           ],
//                         ),
//                       ),
//                     ),
//                     pw.SizedBox(width: 20),
//                     pw.Expanded(
//                       child: pw.Column(
//                         crossAxisAlignment: pw.CrossAxisAlignment.start,
//                         children: [
//                           pw.Text(
//                             'BILL TO:',
//                             style: pw.TextStyle(
//                               fontSize: 12,
//                               fontWeight: pw.FontWeight.bold,
//                               color: PdfColors.grey600,
//                             ),
//                           ),
//                           pw.SizedBox(height: 5),
//                           pw.Text(
//                             subscription.name,
//                             style: pw.TextStyle(
//                               fontSize: 18,
//                               fontWeight: pw.FontWeight.bold,
//                             ),
//                           ),
//                           pw.Text('Phone: ${subscription.phone}'),
//                           if (subscription.purchaseDate != 'N/A')
//                             pw.Text(
//                                 'Purchase Date: ${subscription.purchaseDate}'),
//                           if (subscription.transactionId.isNotEmpty)
//                             pw.Text(
//                                 'Transaction ID: ${subscription.transactionId}'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 pw.SizedBox(height: 40),
//                 pw.Container(
//                   decoration: pw.BoxDecoration(
//                     border: pw.Border.all(color: PdfColors.grey400),
//                     borderRadius:
//                         const pw.BorderRadius.all(pw.Radius.circular(5)),
//                   ),
//                   child: pw.Table(
//                     border: pw.TableBorder.all(color: PdfColors.grey400),
//                     children: [
//                       pw.TableRow(
//                         decoration:
//                             const pw.BoxDecoration(color: PdfColors.grey200),
//                         children: [
//                           pw.Padding(
//                             padding: const pw.EdgeInsets.all(10),
//                             child: pw.Text(
//                               'Description',
//                               style:
//                                   pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                             ),
//                           ),
//                           pw.Padding(
//                             padding: const pw.EdgeInsets.all(10),
//                             child: pw.Text(
//                               'Plan Type',
//                               style:
//                                   pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                             ),
//                           ),
//                           pw.Padding(
//                             padding: const pw.EdgeInsets.all(10),
//                             child: pw.Text(
//                               'Payment Method',
//                               style:
//                                   pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                             ),
//                           ),
//                           pw.Padding(
//                             padding: const pw.EdgeInsets.all(10),
//                             child: pw.Text(
//                               'Amount',
//                               style:
//                                   pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                               textAlign: pw.TextAlign.right,
//                             ),
//                           ),
//                         ],
//                       ),
//                       pw.TableRow(
//                         children: [
//                           pw.Padding(
//                             padding: const pw.EdgeInsets.all(10),
//                             child: pw.Text(
//                                 '${subscription.planName} Subscription'),
//                           ),
//                           pw.Padding(
//                             padding: const pw.EdgeInsets.all(10),
//                             child: pw.Text(subscription.planName),
//                           ),
//                           pw.Padding(
//                             padding: const pw.EdgeInsets.all(10),
//                             child: pw.Text(displayPaymentMethod),
//                           ),
//                           pw.Padding(
//                             padding: const pw.EdgeInsets.all(10),
//                             child: pw.Text(
//                               formattedBaseAmount,
//                               textAlign: pw.TextAlign.right,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//                 pw.SizedBox(height: 20),
//                 pw.Container(
//                   alignment: pw.Alignment.centerRight,
//                   child: pw.Container(
//                     width: 250,
//                     padding: const pw.EdgeInsets.all(15),
//                     decoration: pw.BoxDecoration(
//                       color: PdfColors.grey100,
//                       borderRadius:
//                           const pw.BorderRadius.all(pw.Radius.circular(5)),
//                     ),
//                     child: pw.Column(
//                       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                       children: [
//                         pw.Row(
//                           mainAxisSize: pw.MainAxisSize.max,
//                           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                           children: [
//                             pw.Text('Subtotal:',
//                                 style: const pw.TextStyle(fontSize: 12)),
//                             pw.Text(formattedBaseAmount,
//                                 style: const pw.TextStyle(fontSize: 12)),
//                           ],
//                         ),
//                         pw.SizedBox(height: 5),
//                         pw.Row(
//                           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                           children: [
//                             pw.Text('GST (18%):',
//                                 style: const pw.TextStyle(fontSize: 12)),
//                             pw.Text(formattedGstAmount,
//                                 style: const pw.TextStyle(fontSize: 12)),
//                           ],
//                         ),
//                         pw.Divider(),
//                         pw.Row(
//                           mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                           children: [
//                             pw.Text(
//                               'Total:',
//                               style: pw.TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: pw.FontWeight.bold,
//                               ),
//                             ),
//                             pw.Text(
//                               formattedTotalAmount,
//                               style: pw.TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: pw.FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 pw.SizedBox(height: 30),
//                 pw.Container(
//                   padding: const pw.EdgeInsets.all(15),
//                   decoration: pw.BoxDecoration(
//                     color: subscription.paymentStatus == 'Success'
//                         ? PdfColors.green100
//                         : PdfColors.red100,
//                     borderRadius:
//                         const pw.BorderRadius.all(pw.Radius.circular(5)),
//                   ),
//                   child: pw.Row(
//                     children: [
//                       pw.Text(
//                         'Payment Status: ',
//                         style: pw.TextStyle(
//                           fontSize: 14,
//                           fontWeight: pw.FontWeight.bold,
//                           color: subscription.paymentStatus == 'Success'
//                               ? PdfColors.green800
//                               : PdfColors.red800,
//                         ),
//                       ),
//                       pw.Text(
//                         subscription.paymentStatus,
//                         style: pw.TextStyle(
//                           fontSize: 14,
//                           fontWeight: pw.FontWeight.bold,
//                           color: subscription.paymentStatus == 'Success'
//                               ? PdfColors.green800
//                               : PdfColors.red800,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (subscription.expiryDate != 'N/A') ...[
//                   pw.SizedBox(height: 10),
//                   pw.Container(
//                     padding: const pw.EdgeInsets.all(15),
//                     decoration: pw.BoxDecoration(
//                       color: PdfColors.blue100,
//                       borderRadius:
//                           const pw.BorderRadius.all(pw.Radius.circular(5)),
//                     ),
//                     child: pw.Row(
//                       children: [
//                         pw.Text(
//                           'Subscription Expires: ',
//                           style: pw.TextStyle(
//                             fontSize: 14,
//                             fontWeight: pw.FontWeight.bold,
//                             color: PdfColors.blue800,
//                           ),
//                         ),
//                         pw.Text(
//                           subscription.expiryDate,
//                           style: pw.TextStyle(
//                             fontSize: 14,
//                             fontWeight: pw.FontWeight.bold,
//                             color: PdfColors.blue800,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//                 pw.SizedBox(height: 15),
//                 pw.Padding(
//                   padding: const pw.EdgeInsets.symmetric(horizontal: 12),
//                   child: pw.Text(
//                     "Terms & Conditions",
//                     style: pw.TextStyle(
//                       color: PdfColors.blue900,
//                       fontSize: 11,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 pw.SizedBox(height: 3),
//                 pw.Padding(
//                   padding: const pw.EdgeInsets.symmetric(horizontal: 14),
//                   child: pw.Text(
//                     "By purchasing a subscription to VideosAlarm, you agree to our Terms and Conditions, Privacy Policy, and Cancellation & Refund Policy. Subscriptions are non-refundable except in rare cases of technical errors, as detailed in our policies. You may cancel your subscription anytime, and access will continue until the end of the current billing cycle.",
//                     style: pw.TextStyle(
//                       color: PdfColors.grey700,
//                       fontSize: 10,
//                       fontWeight: pw.FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 pw.Spacer(),
//                 pw.Container(
//                   width: double.infinity,
//                   padding: const pw.EdgeInsets.all(15),
//                   decoration: pw.BoxDecoration(
//                     color: PdfColors.grey200,
//                     borderRadius:
//                         const pw.BorderRadius.all(pw.Radius.circular(5)),
//                   ),
//                   child: pw.Column(
//                     crossAxisAlignment: pw.CrossAxisAlignment.center,
//                     children: [
//                       pw.Text(
//                         'Thank you for your business!',
//                         style: pw.TextStyle(
//                           fontSize: 16,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       pw.SizedBox(height: 5),
//                       pw.Text(
//                         'For any queries, please contact info@videosalarm.com',
//                         style: const pw.TextStyle(
//                             fontSize: 10, color: PdfColors.grey700),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//     return pdf.save();
//   }

//   pw.Widget _buildTotalRow(String label, String value,
//       {bool bold = false, bool big = false}) {
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       children: [
//         pw.Text(
//           label,
//           style: pw.TextStyle(
//             fontSize: big ? 14 : 12,
//             fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
//           ),
//         ),
//         pw.Text(
//           value,
//           style: pw.TextStyle(
//             fontSize: big ? 14 : 12,
//             fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> migrateToSubscriptionCollection() async {
//     _showLoadingDialog('Migrating subscription data...');
//     try {
//       FirebaseFirestore firestore = FirebaseFirestore.instance;
//       QuerySnapshot usersSnapshot = await firestore.collection('users').get();
//       const batchSize = 500;
//       final docs = usersSnapshot.docs;
//       int totalMigrated = 0;

//       for (int i = 0; i < docs.length; i += batchSize) {
//         final batch = firestore.batch();
//         final chunk = docs.skip(i).take(batchSize);

//         for (var doc in chunk) {
//           final data = doc.data() as Map<String, dynamic>;

//           final bool isTestRecord = data['test'] ?? false;

//           if (data['test'] == true) {
//             Map<String, dynamic> subscriptionData = {
//               'userId': doc.id,
//               'name': data['name'] ?? 'Unknown',
//               'phone': data['phone'] ?? 'Unknown',
//               'subscriptionType': data['SubscriptionType'] ?? '',
//               'purchaseToken': data['PurchaseToken'] ?? '',
//               'active': data['Active'] ?? false,
//               'test': isTestRecord,
//               'paymentStatus':
//                   data['PaymentStatus'] ?? _determinePaymentStatus(data),
//               'backendPaymentStatus': data['BackendPaymentStatus'] ?? 'Unknown',
//               'paymentMethod':
//                   data['paymentMethod'] ?? _determinePaymentMethod(data),
//               'subscriptionStartDate': data['SubscriptionStartDate'],
//               'subscriptionExpiryDate': data['SubscriptionExpiryDate'],
//               'updatedAt': data['updatedAt'] ?? FieldValue.serverTimestamp(),
//               'createdAt': FieldValue.serverTimestamp(),
//               'devices': data['devices'] ?? {},
//               'planPrice': _getPlanPrice(data['SubscriptionType'] ?? ''),
//               'planName': _getPlanName(data['SubscriptionType'] ?? ''),
//               'razorpayOrderId': data['razorpayOrderId'],
//               'razorpayPaymentId': data['razorpayPaymentId'],
//               'razorpaySignature': data['razorpaySignature'],
//               'transactionId': data['transactionId'],
//               'receiptUrl': data['receiptUrl'],
//             };

//             subscriptionData.removeWhere((key, value) => value == null);

//             DocumentReference subscriptionRef =
//                 firestore.collection('subscription').doc(doc.id);

//             batch.set(subscriptionRef, subscriptionData);
//             totalMigrated++;
//           } else {
//             if (data.containsKey('SubscriptionType') ||
//                 data.containsKey('PurchaseToken')) {
//               Map<String, dynamic> subscriptionData = {
//                 'userId': doc.id,
//                 'name': data['name'] ?? 'Unknown',
//                 'phone': data['phone'] ?? 'Unknown',
//                 'subscriptionType': data['SubscriptionType'] ?? '',
//                 'purchaseToken': data['PurchaseToken'] ?? '',
//                 'active': data['Active'] ?? false,
//                 'test': isTestRecord,
//                 'paymentStatus':
//                     data['PaymentStatus'] ?? _determinePaymentStatus(data),
//                 'backendPaymentStatus':
//                     data['BackendPaymentStatus'] ?? 'Unknown',
//                 'paymentMethod':
//                     data['paymentMethod'] ?? _determinePaymentMethod(data),
//                 'subscriptionStartDate': data['SubscriptionStartDate'],
//                 'subscriptionExpiryDate': data['SubscriptionExpiryDate'],
//                 'updatedAt': data['updatedAt'] ?? FieldValue.serverTimestamp(),
//                 'createdAt': FieldValue.serverTimestamp(),
//                 'devices': data['devices'] ?? {},
//                 'planPrice': _getPlanPrice(data['SubscriptionType'] ?? ''),
//                 'planName': _getPlanName(data['SubscriptionType'] ?? ''),
//                 'razorpayOrderId': data['razorpayOrderId'],
//                 'razorpayPaymentId': data['razorpayPaymentId'],
//                 'razorpaySignature': data['razorpaySignature'],
//                 'transactionId': data['transactionId'],
//                 'receiptUrl': data['receiptUrl'],
//               };

//               subscriptionData.removeWhere((key, value) => value == null);

//               DocumentReference subscriptionRef =
//                   firestore.collection('subscription').doc(doc.id);

//               batch.set(subscriptionRef, subscriptionData);
//               totalMigrated++;
//             }
//           }
//         }

//         await batch.commit();
//       }

//       Navigator.of(context).pop();
//       _showSuccessSnackBar('Successfully migrated $totalMigrated records');
//       await loadSubscriptions();
//     } catch (e) {
//       Navigator.of(context).pop();
//       _showErrorSnackBar('Migration failed: $e');
//     }
//   }

//   void _showLoadingDialog(String message) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF2A2A2A),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const CircularProgressIndicator(color: Colors.blue),
//             const SizedBox(height: 16),
//             Text(
//               message,
//               style: const TextStyle(color: Colors.white),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _determinePaymentStatus(Map<String, dynamic> data) {
//     if (data.containsKey('PaymentStatus')) {
//       return data['PaymentStatus'];
//     } else if (data.containsKey('Active') && data['Active'] == true) {
//       return 'Success';
//     } else if (data.containsKey('PurchaseToken') &&
//         data['PurchaseToken'].toString().isNotEmpty) {
//       return 'Pending';
//     } else {
//       return 'Failed';
//     }
//   }

//   String _determinePaymentMethod(Map<String, dynamic> data) {
//     if (data.containsKey('paymentMethod')) {
//       return data['paymentMethod'];
//     }
//     final subscriptionType = data['SubscriptionType'];
//     final purchaseToken = data['PurchaseToken']?.toString();
//     if (subscriptionType == 'com.videosalarm.subscription.premium') {
//       return 'iOS';
//     } else if (subscriptionType == 'vip_plan_id') {
//       if (purchaseToken != null && purchaseToken.startsWith('pay_')) {
//         return 'Razorpay';
//       } else {
//         return 'Android';
//       }
//     } else {
//       return 'Unknown';
//     }
//   }

//   List<UserSubscription> get filteredSubscriptions {
//     return subscriptions.where((subscription) {
//       final matchesSearch = subscription.name
//               .toLowerCase()
//               .contains(searchQuery.toLowerCase()) ||
//           subscription.phone.toLowerCase().contains(searchQuery.toLowerCase());

//       final matchesStatus =
//           statusFilter == 'All' || subscription.paymentStatus == statusFilter;

//       final matchesBackendStatus = backendStatusFilter == 'All' ||
//           subscription.backendPaymentStatus.toLowerCase() ==
//               backendStatusFilter.toLowerCase();

//       final matchesPaymentMethod = paymentMethodFilter == 'All' ||
//           subscription.paymentMethod.toLowerCase() ==
//               paymentMethodFilter.toLowerCase();

//       bool matchesDateRange = true;
//       if (isDateFilterActive && selectedDateRange != null) {
//         if (subscription.purchaseDateTime != null) {
//           final purchaseDate = subscription.purchaseDateTime!;
//           matchesDateRange = (purchaseDate.isAfter(selectedDateRange!.start) ||
//                   purchaseDate.isAtSameMomentAs(selectedDateRange!.start)) &&
//               (purchaseDate.isBefore(
//                       selectedDateRange!.end.add(Duration(days: 1))) ||
//                   purchaseDate.isAtSameMomentAs(selectedDateRange!.end));
//         } else {
//           matchesDateRange = false;
//         }
//       }

//       return matchesSearch &&
//           matchesStatus &&
//           matchesBackendStatus &&
//           matchesPaymentMethod &&
//           matchesDateRange;
//     }).toList();
//   }

//   Future<void> _selectDateRange() async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       initialEntryMode: DatePickerEntryMode.input,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       initialDateRange: selectedDateRange,
//     );
//     if (picked != null && picked != selectedDateRange) {
//       setState(() {
//         selectedDateRange = picked;
//       });
//       _generateFilteredPdf();
//     }
//   }

//   Future<void> _selectDateRangeForFilter() async {
//     final DateTimeRange? picked = await showDateRangePicker(
//       context: context,
//       initialEntryMode: DatePickerEntryMode.input,
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//       initialDateRange: selectedDateRange,
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.dark(
//               primary: Colors.blue.shade400,
//               onPrimary: Colors.white,
//               surface: const Color(0xFF2A2A2A),
//               onSurface: Colors.white,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );

//     if (picked != null) {
//       setState(() {
//         selectedDateRange = picked;
//         isDateFilterActive = true;
//       });
//     }
//   }

//   void _clearDateFilter() {
//     setState(() {
//       selectedDateRange = null;
//       isDateFilterActive = false;
//     });
//   }

//   Widget _buildDateFilterChip() {
//     if (!isDateFilterActive || selectedDateRange == null) {
//       return const SizedBox.shrink();
//     }

//     final startDate =
//         DateFormat('dd MMM yyyy').format(selectedDateRange!.start);
//     final endDate = DateFormat('dd MMM yyyy').format(selectedDateRange!.end);

//     return Container(
//       margin: const EdgeInsets.only(top: 12),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade900.withOpacity(0.3),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.date_range, color: Colors.blue.shade300, size: 18),
//           const SizedBox(width: 8),
//           Text(
//             'Filter: $startDate - $endDate',
//             style: TextStyle(
//               color: Colors.blue.shade300,
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const SizedBox(width: 8),
//           InkWell(
//             onTap: _clearDateFilter,
//             child: Icon(Icons.close, color: Colors.blue.shade300, size: 18),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _generateFilteredPdf() async {
//     if (selectedDateRange == null) {
//       _showErrorSnackBar('Please select a date range first.');
//       return;
//     }
//     final filtered = subscriptions.where((sub) {
//       if (sub.purchaseDateTime == null) return false;
//       final purchaseDate = sub.purchaseDateTime!;
//       return (purchaseDate.isAfter(selectedDateRange!.start) ||
//               purchaseDate.isAtSameMomentAs(selectedDateRange!.start)) &&
//           (purchaseDate.isBefore(selectedDateRange!.end) ||
//               purchaseDate.isAtSameMomentAs(selectedDateRange!.end));
//     }).toList();

//     final startDate = DateFormat('yyyy-MM-dd').format(selectedDateRange!.start);
//     final endDate = DateFormat('yyyy-MM-dd').format(selectedDateRange!.end);

//     await createPdf(filtered, 'Subscriptions from $startDate to $endDate');
//   }

//   Future<void> createPdf(List<UserSubscription> data, String title) async {
//     _showLoadingDialog('Generating PDF...');
//     try {
//       final pdf = pw.Document();
//       pdf.addPage(
//         pw.MultiPage(
//           pageFormat: PdfPageFormat.a4,
//           build: (pw.Context context) {
//             return [
//               pw.Header(
//                 level: 0,
//                 child: pw.Text(
//                   title,
//                   style: pw.TextStyle(
//                       fontSize: 20, fontWeight: pw.FontWeight.bold),
//                 ),
//               ),
//               pw.Table.fromTextArray(
//                 headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
//                 headers: [
//                   'Name',
//                   'Phone',
//                   'Plan',
//                   'Price',
//                   'Payment Status',
//                   'Method',
//                   'Expiry'
//                 ],
//                 data: data
//                     .map((sub) => [
//                           sub.name,
//                           sub.phone,
//                           sub.planName,
//                           sub.price,
//                           sub.paymentStatus,
//                           sub.paymentMethod,
//                           sub.expiryDate
//                         ])
//                     .toList(),
//               ),
//             ];
//           },
//         ),
//       );
//       final bytes = await pdf.save();
//       Navigator.of(context).pop();

//       if (kIsWeb) {
//         await Printing.sharePdf(
//             bytes: bytes, filename: 'subscriptions_report.pdf');
//       } else {
//         final directory = await getApplicationDocumentsDirectory();
//         final file = File('${directory.path}/subscriptions_report.pdf');
//         await file.writeAsBytes(bytes);
//         await Printing.sharePdf(
//             bytes: bytes, filename: 'subscriptions_report.pdf');
//       }

//       _showSuccessSnackBar('PDF generated successfully');
//     } catch (e) {
//       Navigator.of(context).pop();
//       _showErrorSnackBar('Error generating PDF: $e');
//     }
//   }

//   Future<void> _exportToExcel(List<UserSubscription> data, String title) async {
//     _showLoadingDialog('Generating Excel file...');
//     try {
//       final excel = Excel.createExcel();
//       final Sheet sheetObject = excel[title];

//       List<String> headers = [
//         'User ID',
//         'Name',
//         'Phone',
//         'Plan Name',
//         'Price',
//         'Payment Status',
//         'Backend Status',
//         'Payment Method',
//         'Purchase Date',
//         'Expiry Date',
//         'Is Active',
//         'Purchase Token'
//       ];
//       sheetObject
//           .appendRow(headers.map((header) => TextCellValue(header)).toList());

//       for (var subscription in data) {
//         List<CellValue> row = [
//           TextCellValue(subscription.userId),
//           TextCellValue(subscription.name),
//           TextCellValue(subscription.phone),
//           TextCellValue(subscription.planName),
//           TextCellValue(subscription.price),
//           TextCellValue(subscription.paymentStatus),
//           TextCellValue(subscription.backendPaymentStatus),
//           TextCellValue(subscription.paymentMethod),
//           TextCellValue(subscription.purchaseDate),
//           TextCellValue(subscription.expiryDate),
//           TextCellValue(subscription.isActive.toString()),
//           TextCellValue(subscription.purchaseToken),
//         ];
//         sheetObject.appendRow(row);
//       }

//       Navigator.of(context).pop();

//       final String fileName =
//           'Subscriptions_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
//       var fileBytes = excel.save();

//       if (fileBytes != null) {
//         if (!kIsWeb) {
//           final directory = await getApplicationDocumentsDirectory();
//           final path = '${directory.path}/$fileName';
//           final file = File(path);
//           await file.writeAsBytes(fileBytes, flush: true);
//           _showSuccessSnackBar('Excel file saved to Downloads');
//         } else {
//           excel.save(fileName: fileName);
//           _showSuccessSnackBar('Excel file is being downloaded.');
//         }
//       } else {
//         _showErrorSnackBar('Failed to generate Excel file.');
//       }
//     } catch (e) {
//       Navigator.of(context).pop();
//       _showErrorSnackBar('Error generating Excel file: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0F0F0F),
//       body: CustomScrollView(
//         slivers: [
//           _buildAppBar(),
//           _buildInfoBanner(),
//           _buildFilters(),
//           _buildStatsCards(),
//           _buildContent(),
//         ],
//       ),
//     );
//   }

//   Widget _buildAppBar() {
//     return SliverAppBar(
//       floating: true,
//       pinned: true,
//       elevation: 0,
//       backgroundColor: const Color(0xFF1A1A1A),
//       title: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.blue.shade400, Colors.purple.shade400],
//               ),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: const Icon(Icons.analytics_outlined,
//                 color: Colors.white, size: 20),
//           ),
//           const SizedBox(width: 12),
//           const Text('Subscription Analytics',
//               style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600)),
//         ],
//       ),
//       actions: [
//         _buildActionButton(
//           icon: Icons.table_chart_outlined,
//           label: 'Excel',
//           onPressed: () =>
//               _exportToExcel(filteredSubscriptions, 'Filtered Subscriptions'),
//           tooltip: 'Export to Excel',
//           color: Colors.green.shade400,
//         ),
//         _buildActionButton(
//           icon: Icons.picture_as_pdf_outlined,
//           label: 'PDF',
//           onPressed: () => createPdf(
//               subscriptions
//                   .where(
//                       (s) => s.backendPaymentStatus.toLowerCase() == 'active')
//                   .toList(),
//               'Active Subscriptions Report'),
//           tooltip: 'Generate PDF Report',
//           color: Colors.red.shade400,
//         ),
//         _buildActionButton(
//           icon: Icons.date_range,
//           label: 'Date PDF',
//           onPressed: _selectDateRange,
//           tooltip: 'Generate PDF by Date Range',
//           color: Colors.orange.shade400,
//         ),
//         _buildActionButton(
//           icon: Icons.cloud_sync_outlined,
//           label: 'Migrate',
//           onPressed: migrateToSubscriptionCollection,
//           tooltip: 'Migrate Data',
//           color: Colors.cyan.shade400,
//         ),
//         _buildActionButton(
//           icon: Icons.refresh,
//           label: 'Refresh',
//           onPressed: loadSubscriptions,
//           tooltip: 'Refresh Data',
//           color: Colors.blue.shade400,
//         ),
//         _buildActionButton(
//           icon: isGridView ? Icons.table_rows : Icons.grid_view,
//           label: isGridView ? 'Table' : 'Grid',
//           onPressed: () => setState(() => isGridView = !isGridView),
//           tooltip: isGridView ? 'Table View' : 'Grid View',
//           color: Colors.purple.shade400,
//         ),
//         const SizedBox(width: 8),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onPressed,
//     required String tooltip,
//     required Color color,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 4.0),
//       child: Tooltip(
//         message: tooltip,
//         child: TextButton.icon(
//           onPressed: onPressed,
//           icon: Icon(icon, color: color, size: 18),
//           label: Text(
//             label,
//             style: TextStyle(
//                 color: color, fontWeight: FontWeight.w600, fontSize: 13),
//           ),
//           style: TextButton.styleFrom(
//             backgroundColor: const Color(0xFF2A2A2A),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoBanner() {
//     return SliverToBoxAdapter(
//       child: Container(
//         margin: const EdgeInsets.all(16),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Colors.blue.withOpacity(0.1),
//               Colors.purple.withOpacity(0.1)
//             ],
//           ),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade400,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child:
//                   const Icon(Icons.info_outline, color: Colors.white, size: 20),
//             ),
//             const SizedBox(width: 12),
//             const Expanded(
//               child: Text(
//                 'Use the sync button to migrate subscription data to the dedicated collection for better organization.',
//                 style: TextStyle(color: Colors.white70, fontSize: 14),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFilters() {
//     return SliverToBoxAdapter(
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1A1A1A),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.3),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Filters',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: _selectDateRangeForFilter,
//                   icon: Icon(
//                     isDateFilterActive
//                         ? Icons.filter_alt
//                         : Icons.filter_alt_outlined,
//                     size: 18,
//                   ),
//                   label: Text(
//                     isDateFilterActive ? 'Change Dates' : 'Filter by Date',
//                     style: const TextStyle(fontSize: 13),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: isDateFilterActive
//                         ? Colors.blue.shade600
//                         : const Color(0xFF2A2A2A),
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 10),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             _buildDateFilterChip(),
//             const SizedBox(height: 16),
//             _buildSearchField(),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: _buildDropdownFilter(
//                     'Payment Status',
//                     statusFilter,
//                     statusOptions,
//                     (value) => setState(() => statusFilter = value!),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildDropdownFilter(
//                     'Backend Status',
//                     backendStatusFilter,
//                     backendStatusOptions,
//                     (value) => setState(() => backendStatusFilter = value!),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: _buildDropdownFilter(
//                     'Payment Method',
//                     paymentMethodFilter,
//                     paymentMethodOptions,
//                     (value) => setState(() => paymentMethodFilter = value!),
//                   ),
//                 ),
//               ],
//             ),
//             if (isDateFilterActive ||
//                 statusFilter != 'All' ||
//                 backendStatusFilter != 'All' ||
//                 paymentMethodFilter != 'All' ||
//                 searchQuery.isNotEmpty) ...[
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Text(
//                     'Showing ${filteredSubscriptions.length} of ${subscriptions.length} records',
//                     style: TextStyle(
//                       color: Colors.grey[400],
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   const Spacer(),
//                   if (isDateFilterActive ||
//                       statusFilter != 'All' ||
//                       backendStatusFilter != 'All' ||
//                       paymentMethodFilter != 'All' ||
//                       searchQuery.isNotEmpty)
//                     TextButton.icon(
//                       onPressed: () {
//                         setState(() {
//                           searchQuery = '';
//                           statusFilter = 'All';
//                           backendStatusFilter = 'All';
//                           paymentMethodFilter = 'All';
//                           _clearDateFilter();
//                         });
//                       },
//                       icon: const Icon(Icons.clear_all, size: 16),
//                       label: const Text('Clear All Filters',
//                           style: TextStyle(fontSize: 12)),
//                       style: TextButton.styleFrom(
//                         foregroundColor: Colors.orange.shade400,
//                       ),
//                     ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchField() {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFF2A2A2A),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: TextField(
//         style: const TextStyle(color: Colors.white),
//         decoration: InputDecoration(
//           hintText: 'Search by name or phone...',
//           hintStyle: TextStyle(color: Colors.grey[500]),
//           prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
//           suffixIcon: searchQuery.isNotEmpty
//               ? IconButton(
//                   icon: Icon(Icons.clear, color: Colors.grey[500]),
//                   onPressed: () => setState(() => searchQuery = ''),
//                 )
//               : null,
//           border: InputBorder.none,
//           contentPadding:
//               const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         ),
//         onChanged: (value) => setState(() => searchQuery = value),
//       ),
//     );
//   }

//   Widget _buildDropdownFilter(String label, String value, List<String> options,
//       Function(String?) onChanged) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//               color: Colors.grey[400],
//               fontSize: 12,
//               fontWeight: FontWeight.w500),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: BoxDecoration(
//             color: const Color(0xFF2A2A2A),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: DropdownButtonFormField<String>(
//             value: value,
//             style: const TextStyle(color: Colors.white),
//             dropdownColor: const Color(0xFF2A2A2A),
//             decoration: const InputDecoration(
//               border: InputBorder.none,
//               contentPadding:
//                   EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             ),
//             items: options.map((option) {
//               return DropdownMenuItem(
//                 value: option,
//                 child:
//                     Text(option, style: const TextStyle(color: Colors.white)),
//               );
//             }).toList(),
//             onChanged: onChanged,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatsCards() {
//     return SliverToBoxAdapter(
//       child: Container(
//         height: 120,
//         margin: const EdgeInsets.all(16),
//         child: ListView(
//           scrollDirection: Axis.horizontal,
//           children: [
//             _buildStatCard(
//                 'Success',
//                 subscriptions
//                     .where((s) => s.paymentStatus == 'Success')
//                     .length
//                     .toString(),
//                 Icons.check_circle,
//                 Colors.green),
//             _buildStatCard(
//                 'Failed',
//                 subscriptions
//                     .where((s) => s.paymentStatus == 'Failed')
//                     .length
//                     .toString(),
//                 Icons.error,
//                 Colors.red),
//             _buildStatCard(
//                 'Active',
//                 subscriptions
//                     .where(
//                         (s) => s.backendPaymentStatus.toLowerCase() == 'active')
//                     .length
//                     .toString(),
//                 Icons.verified,
//                 Colors.teal),
//             _buildStatCard(
//                 'iOS',
//                 subscriptions
//                     .where((s) => s.paymentMethod.toLowerCase() == 'ios')
//                     .length
//                     .toString(),
//                 Icons.phone_iphone,
//                 Colors.purple),
//             _buildStatCard(
//                 'Android',
//                 subscriptions
//                     .where((s) => s.paymentMethod.toLowerCase() == 'android')
//                     .length
//                     .toString(),
//                 Icons.android,
//                 Colors.orange),
//             _buildStatCard(
//                 'Razorpay',
//                 subscriptions
//                     .where((s) => s.paymentMethod.toLowerCase() == 'razorpay')
//                     .length
//                     .toString(),
//                 Icons.payment,
//                 Colors.cyan),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatCard(
//       String title, String value, IconData icon, Color color) {
//     return Container(
//       width: 140,
//       margin: const EdgeInsets.only(right: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Icon(icon, color: color, size: 24),
//               Text(
//                 value,
//                 style: TextStyle(
//                   color: color,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           const Spacer(),
//           Text(
//             title,
//             style: const TextStyle(
//               color: Colors.white70,
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContent() {
//     if (isLoading) {
//       return const SliverFillRemaining(
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(color: Colors.blue),
//               SizedBox(height: 16),
//               Text('Loading subscriptions...',
//                   style: TextStyle(color: Colors.white70)),
//             ],
//           ),
//         ),
//       );
//     }
//     return isGridView ? _buildGridView() : _buildTableView();
//   }

//   Widget _buildGridView() {
//     return SliverPadding(
//       padding: const EdgeInsets.all(16),
//       sliver: SliverGrid(
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 2,
//           mainAxisSpacing: 16,
//           crossAxisSpacing: 16,
//           childAspectRatio: 0.8,
//         ),
//         delegate: SliverChildBuilderDelegate(
//           (context, index) =>
//               _buildSubscriptionCard(filteredSubscriptions[index]),
//           childCount: filteredSubscriptions.length,
//         ),
//       ),
//     );
//   }

//   Widget _buildSubscriptionCard(UserSubscription subscription) {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1A1A1A),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: _getStatusColor(subscription.paymentStatus)
//                       .withOpacity(0.2),
//                   child: Text(
//                     subscription.name.isNotEmpty
//                         ? subscription.name[0].toUpperCase()
//                         : '?',
//                     style: TextStyle(
//                       color: _getStatusColor(subscription.paymentStatus),
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         subscription.name,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         subscription.phone,
//                         style: TextStyle(color: Colors.grey[400], fontSize: 12),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             _buildCardRow('Plan', subscription.planName),
//             _buildCardRow('Price', subscription.price),
//             _buildCardRow('Method', subscription.paymentMethod),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 _buildStatusChip(subscription.paymentStatus,
//                     _getStatusColor(subscription.paymentStatus)),
//                 const SizedBox(width: 8),
//                 _buildStatusChip(subscription.backendPaymentStatus,
//                     _getBackendStatusColor(subscription.backendPaymentStatus)),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCardRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(color: Colors.grey[400], fontSize: 12),
//           ),
//           Text(
//             value,
//             style: const TextStyle(
//                 color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusChip(String status, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Text(
//         status,
//         style: TextStyle(
//           color: color,
//           fontSize: 10,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }

//   Widget _buildTableView() {
//     return SliverToBoxAdapter(
//       child: Container(
//         margin: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1A1A1A),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.2),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Container(
//               width: 1600,
//               padding: const EdgeInsets.all(16),
//               child: Theme(
//                 data: Theme.of(context).copyWith(
//                   dataTableTheme: DataTableThemeData(
//                     headingRowColor:
//                         MaterialStateProperty.all(const Color(0xFF2A2A2A)),
//                     dataRowColor: MaterialStateProperty.all(Colors.transparent),
//                     dividerThickness: 0.5,
//                   ),
//                 ),
//                 child: DataTable(
//                   columnSpacing: 16,
//                   headingRowHeight: 56,
//                   dataRowHeight: 64,
//                   headingTextStyle: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                     fontSize: 14,
//                   ),
//                   dataTextStyle:
//                       const TextStyle(color: Colors.white70, fontSize: 13),
//                   columns: const [
//                     DataColumn(
//                         label:
//                             SizedBox(width: 120, child: Text('Purchase Date'))),
//                     DataColumn(
//                         label: SizedBox(width: 140, child: Text('Customer'))),
//                     DataColumn(
//                         label: SizedBox(width: 120, child: Text('Phone'))),
//                     DataColumn(
//                         label: SizedBox(width: 100, child: Text('Plan'))),
//                     DataColumn(
//                         label: SizedBox(width: 80, child: Text('Price'))),
//                     DataColumn(
//                         label: SizedBox(
//                             width: 120, child: Text('Payment Status'))),
//                     DataColumn(
//                         label: SizedBox(
//                             width: 120, child: Text('Backend Status'))),
//                     DataColumn(
//                         label: SizedBox(width: 120, child: Text('Method'))),
//                     DataColumn(
//                         label:
//                             SizedBox(width: 120, child: Text('Expiry Date'))),
//                   ],
//                   rows: filteredSubscriptions.map((subscription) {
//                     return DataRow(
//                       cells: [
//                         DataCell(
//                           SizedBox(
//                             width: 120,
//                             child: Text(
//                               subscription.purchaseDate,
//                               style: const TextStyle(color: Colors.white70),
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           SizedBox(
//                             width: 140,
//                             child: Row(
//                               children: [
//                                 CircleAvatar(
//                                   radius: 16,
//                                   backgroundColor: _getStatusColor(
//                                           subscription.paymentStatus)
//                                       .withOpacity(0.2),
//                                   child: Text(
//                                     subscription.name.isNotEmpty
//                                         ? subscription.name[0].toUpperCase()
//                                         : '?',
//                                     style: TextStyle(
//                                       color: _getStatusColor(
//                                           subscription.paymentStatus),
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     subscription.name,
//                                     style: const TextStyle(color: Colors.white),
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           SizedBox(
//                             width: 120,
//                             child: Text(
//                               subscription.phone,
//                               style: const TextStyle(color: Colors.white70),
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           SizedBox(
//                             width: 100,
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Text(
//                                 'Premium',
//                                 style: TextStyle(
//                                   color: Colors.blue.shade300,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           SizedBox(
//                             width: 80,
//                             child: Text(
//                               subscription.price,
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           SizedBox(
//                             width: 120,
//                             child: _buildEnhancedStatusChip(
//                               subscription.paymentStatus,
//                               _getStatusColor(subscription.paymentStatus),
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           SizedBox(
//                             width: 120,
//                             child: _buildEnhancedStatusChip(
//                               subscription.backendPaymentStatus,
//                               _getBackendStatusColor(
//                                   subscription.backendPaymentStatus),
//                             ),
//                           ),
//                         ),
//                         DataCell(
//                           SizedBox(
//                             width: 120,
//                             child: _buildMethodChip(subscription.paymentMethod),
//                           ),
//                         ),
//                         DataCell(
//                           SizedBox(
//                             width: 120,
//                             child: Text(
//                               subscription.expiryDate,
//                               style: const TextStyle(color: Colors.white70),
//                             ),
//                           ),
//                         ),
//                         // DataCell(
//                         //   SizedBox(
//                         //     width: 100,
//                         //     child: IconButton(
//                         //       icon: const Icon(Icons.receipt,
//                         //           color: Colors.white),
//                         //       onPressed: () =>
//                         //           _generateInvoiceForUser(subscription),
//                         //     ),
//                         //   ),
//                         // ),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEnhancedStatusChip(String status, Color color) {
//     IconData icon;
//     switch (status.toLowerCase()) {
//       case 'success':
//       case 'active':
//         icon = Icons.check_circle;
//         break;
//       case 'failed':
//       case 'inactive':
//         icon = Icons.error;
//         break;
//       case 'pending':
//         icon = Icons.schedule;
//         break;
//       case 'cancelled':
//       case 'aborted':
//         icon = Icons.cancel;
//         break;
//       default:
//         icon = Icons.help;
//     }
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 14),
//           const SizedBox(width: 6),
//           Text(
//             status,
//             style: TextStyle(
//               color: color,
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMethodChip(String method) {
//     IconData icon;
//     Color color;
//     switch (method.toLowerCase()) {
//       case 'ios':
//         icon = Icons.phone_iphone;
//         color = Colors.purple;
//         break;
//       case 'android':
//         icon = Icons.android;
//         color = Colors.green;
//         break;
//       case 'razorpay':
//         icon = Icons.payment;
//         color = Colors.blue;
//         break;
//       default:
//         icon = Icons.help;
//         color = Colors.grey;
//     }
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.15),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: color, size: 14),
//           const SizedBox(width: 6),
//           Text(
//             method,
//             style: TextStyle(
//               color: color,
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'success':
//         return Colors.green;
//       case 'failed':
//         return Colors.red;
//       case 'aborted':
//       case 'cancelled':
//         return Colors.orange;
//       case 'pending':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   Color _getBackendStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'active':
//         return Colors.green;
//       case 'inactive':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   Color _getPaymentMethodColor(String method) {
//     switch (method.toLowerCase()) {
//       case 'ios':
//         return Colors.purple;
//       case 'android':
//         return Colors.orange;
//       case 'razorpay':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   static String _getPlanName(String subscriptionType) {
//     switch (subscriptionType) {
//       case 'vip_plan_id':
//         return 'VIP Plan';
//       case 'com.videosalarm.subscription.premium':
//         return 'Premium Plan';
//       default:
//         return 'Premium Plan';
//     }
//   }

//   static String _getPlanPrice(String subscriptionType) {
//     switch (subscriptionType) {
//       case 'vip_plan_id':
//       case 'com.videosalarm.subscription.premium':
//         return '₹99.00';
//       default:
//         return '₹99.00';
//     }
//   }
// }

// class UserSubscription {
//   final String userId;
//   final String name;
//   final String phone;
//   final String subscriptionType;
//   final String planName;
//   final String price;
//   final String paymentStatus;
//   final String backendPaymentStatus;
//   final String paymentMethod;
//   final String purchaseToken;
//   final String purchaseDate;
//   final DateTime? purchaseDateTime;
//   final String expiryDate;
//   final bool isActive;
//   final bool isTest;
//   final String transactionId;
//   final Map<String, dynamic>? devices;

//   UserSubscription({
//     required this.userId,
//     required this.name,
//     required this.phone,
//     required this.subscriptionType,
//     required this.planName,
//     required this.price,
//     required this.paymentStatus,
//     required this.backendPaymentStatus,
//     required this.paymentMethod,
//     required this.purchaseToken,
//     required this.purchaseDate,
//     required this.purchaseDateTime,
//     required this.expiryDate,
//     required this.isActive,
//     required this.isTest,
//     required this.transactionId,
//     this.devices,
//   });

//   factory UserSubscription.fromSubscriptionCollection(
//       String documentId, Map<String, dynamic> data) {
//     final subscriptionType = data['subscriptionType'] ?? '';
//     final planName = _getPlanName(subscriptionType);
//     final price = data['planPrice'] ?? _getPlanPrice(subscriptionType);
//     String paymentStatus = data['paymentStatus'] ?? 'Unknown';
//     String backendPaymentStatus = data['backendPaymentStatus'] ?? 'Unknown';
//     if (backendPaymentStatus != 'Unknown') {
//       backendPaymentStatus =
//           backendPaymentStatus.substring(0, 1).toUpperCase() +
//               backendPaymentStatus.substring(1).toLowerCase();
//     }

//     String paymentMethod = data['paymentMethod'] ?? 'Unknown';
//     if (paymentMethod != 'Unknown') {
//       switch (paymentMethod.toLowerCase()) {
//         case 'ios':
//           paymentMethod = 'iOS';
//           break;
//         case 'android':
//           paymentMethod = 'Android';
//           break;
//         case 'razorpay':
//           paymentMethod = 'Razorpay';
//           break;
//         default:
//           paymentMethod = paymentMethod.substring(0, 1).toUpperCase() +
//               paymentMethod.substring(1).toLowerCase();
//       }
//     }

//     String purchaseDate = 'N/A';
//     DateTime? purchaseDateTime;
//     String expiryDate = 'N/A';

//     if (data.containsKey('subscriptionStartDate') &&
//         data['subscriptionStartDate'] != null) {
//       final startDate = (data['subscriptionStartDate'] as Timestamp).toDate();
//       purchaseDate = DateFormat('yyyy-MM-dd HH:mm').format(startDate);
//       purchaseDateTime = startDate;
//     }

//     if (data.containsKey('subscriptionExpiryDate') &&
//         data['subscriptionExpiryDate'] != null) {
//       final expiry = (data['subscriptionExpiryDate'] as Timestamp).toDate();
//       expiryDate = DateFormat('yyyy-MM-dd HH:mm').format(expiry);
//     }

//     return UserSubscription(
//       userId: data['userId'] ?? documentId,
//       name: data['name'] ?? 'Unknown',
//       phone: data['phone'] ?? 'Unknown',
//       subscriptionType: subscriptionType,
//       planName: planName,
//       price: price,
//       paymentStatus: paymentStatus,
//       backendPaymentStatus: backendPaymentStatus,
//       paymentMethod: paymentMethod,
//       purchaseToken: data['purchaseToken'] ?? '',
//       purchaseDate: purchaseDate,
//       purchaseDateTime: purchaseDateTime,
//       expiryDate: expiryDate,
//       isActive: data['active'] ?? false,
//       isTest: data['test'] ?? false,
//       transactionId: data['transactionId'] ?? '',
//       devices: data['devices'] is Map<String, dynamic>
//           ? data['devices'] as Map<String, dynamic>?
//           : data['devices'] is List
//               ? (data['devices'] as List)
//                   .asMap()
//                   .map((key, value) => MapEntry(key.toString(), value))
//               : null,
//     );
//   }

//   factory UserSubscription.fromFirestore(
//       String userId, Map<String, dynamic> data) {
//     final subscriptionType = data['SubscriptionType'] ?? '';
//     final planName = _getPlanName(subscriptionType);
//     final price = _getPlanPrice(subscriptionType);
//     String paymentStatus = 'Unknown';
//     if (data.containsKey('PaymentStatus')) {
//       paymentStatus = data['PaymentStatus'];
//     } else if (data.containsKey('Active') && data['Active'] == true) {
//       paymentStatus = 'Success';
//     } else if (data.containsKey('PurchaseToken') &&
//         data['PurchaseToken'].toString().isNotEmpty) {
//       paymentStatus = 'Pending';
//     } else {
//       paymentStatus = 'Failed';
//     }
//     String backendPaymentStatus = 'Unknown';
//     if (data.containsKey('BackendPaymentStatus')) {
//       backendPaymentStatus = data['BackendPaymentStatus'].toString();
//       backendPaymentStatus =
//           backendPaymentStatus.substring(0, 1).toUpperCase() +
//               backendPaymentStatus.substring(1).toLowerCase();
//     }

//     String paymentMethod = 'Unknown';
//     if (data.containsKey('paymentMethod')) {
//       paymentMethod = data['paymentMethod'].toString();
//       switch (paymentMethod.toLowerCase()) {
//         case 'ios':
//           paymentMethod = 'iOS';
//           break;
//         case 'android':
//           paymentMethod = 'Android';
//           break;
//         case 'razorpay':
//           paymentMethod = 'Razorpay';
//           break;
//         default:
//           paymentMethod = paymentMethod.substring(0, 1).toUpperCase() +
//               paymentMethod.substring(1).toLowerCase();
//       }
//     }

//     String purchaseDate = 'N/A';
//     DateTime? purchaseDateTime;
//     String expiryDate = 'N/A';

//     if (data.containsKey('SubscriptionStartDate')) {
//       final startDate = (data['SubscriptionStartDate'] as Timestamp).toDate();
//       purchaseDate = DateFormat('yyyy-MM-dd HH:mm').format(startDate);
//       purchaseDateTime = startDate;
//     }

//     if (data.containsKey('SubscriptionExpiryDate')) {
//       final expiry = (data['SubscriptionExpiryDate'] as Timestamp).toDate();
//       expiryDate = DateFormat('yyyy-MM-dd HH:mm').format(expiry);
//     }

//     return UserSubscription(
//       userId: userId,
//       name: data['name'] ?? 'Unknown',
//       phone: data['phone'] ?? 'Unknown',
//       subscriptionType: subscriptionType,
//       planName: planName,
//       price: price,
//       paymentStatus: paymentStatus,
//       backendPaymentStatus: backendPaymentStatus,
//       paymentMethod: paymentMethod,
//       purchaseToken: data['PurchaseToken'] ?? '',
//       purchaseDate: purchaseDate,
//       purchaseDateTime: purchaseDateTime,
//       expiryDate: expiryDate,
//       isActive: data['Active'] ?? false,
//       isTest: data['test'] ?? false,
//       transactionId: data['transactionId'] ?? '',
//       devices: data['devices'] is Map<String, dynamic>
//           ? data['devices'] as Map<String, dynamic>?
//           : data['devices'] is List
//               ? (data['devices'] as List)
//                   .asMap()
//                   .map((key, value) => MapEntry(key.toString(), value))
//               : null,
//     );
//   }

//   static String _getPlanName(String subscriptionType) {
//     switch (subscriptionType) {
//       case 'vip_plan_id':
//         return 'VIP Plan';
//       case 'com.videosalarm.subscription.premium':
//         return 'Premium Plan';
//       default:
//         return 'Premium Plan';
//     }
//   }

//   static String _getPlanPrice(String subscriptionType) {
//     switch (subscriptionType) {
//       case 'vip_plan_id':
//       case 'com.videosalarm.subscription.premium':
//         return '₹99.00';
//       default:
//         return '₹99.00';
//     }
//   }
// }





import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionTrackerPage extends StatefulWidget {
  const SubscriptionTrackerPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionTrackerPage> createState() =>
      _SubscriptionTrackerPageState();
}

class _SubscriptionTrackerPageState extends State<SubscriptionTrackerPage>
    with TickerProviderStateMixin {
  List<UserSubscription> subscriptions = [];
  bool isLoading = true;
  String searchQuery = '';
  String statusFilter = 'All';
  String backendStatusFilter = 'All';
  String paymentMethodFilter = 'All';
  bool isGridView = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  DateTimeRange? selectedDateRange;
  bool isDateFilterActive = false;

  final List<String> statusOptions = [
    'All',
    'Success',
    'Failed',
    'Aborted',
    'Cancelled',
    'Pending'
  ];
  final List<String> backendStatusOptions = [
    'All',
    'Active',
    'Unknown',
    'Expired'
  ];

  // Options for the inline dropdown (no 'All')
  final List<String> backendStatusEditOptions = [
    'Active',
    'Unknown',
    'Expired'
  ];

  final List<String> paymentMethodOptions = [
    'All',
    'iOS',
    'Android',
    'Razorpay'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    loadSubscriptions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> loadSubscriptions() async {
    setState(() => isLoading = true);
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('subscription')
          .orderBy('updatedAt', descending: true)
          .get();
      List<UserSubscription> loadedSubscriptions = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final bool isTestRecord = data['test'] ?? false;
        if (isTestRecord) continue;
        final subscription =
            UserSubscription.fromSubscriptionCollection(doc.id, data);
        loadedSubscriptions.add(subscription);
      }

      setState(() {
        subscriptions = loadedSubscriptions;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print('Error loading subscriptions: $e');
      setState(() => isLoading = false);
      _showErrorSnackBar(
          'Failed to load subscriptions: $e. You may need to create a composite index in Firestore.');
    }
  }

  /// Updates BackendPaymentStatus in the `users` collection
  Future<void> _updateBackendStatus(
      UserSubscription subscription, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(subscription.userId)
          .update({'BackendPaymentStatus': newStatus});

      // Also update local state
      setState(() {
        final index =
            subscriptions.indexWhere((s) => s.userId == subscription.userId);
        if (index != -1) {
          subscriptions[index] =
              subscriptions[index].copyWith(backendPaymentStatus: newStatus);
        }
      });

      _showSuccessSnackBar(
          'Backend status updated to "$newStatus" for ${subscription.name}');
    } catch (e) {
      _showErrorSnackBar('Failed to update status: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInvoiceDownloadDialog(String userName, String downloadUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.green.shade400),
            const SizedBox(width: 10),
            const Text('Invoice Available',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('An invoice has been found for $userName.',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      if (await canLaunchUrl(Uri.parse(downloadUrl))) {
                        await launchUrl(Uri.parse(downloadUrl));
                      } else {
                        _showErrorSnackBar('Could not launch invoice URL.');
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _createInvoicePdf(
      UserSubscription subscription, String invoiceNumber) async {
    final pdf = pw.Document();

    final double totalAmount =
        double.tryParse(subscription.price.replaceAll('₹', '').trim()) ?? 0.0;
    final double baseAmount = totalAmount / 1.18;
    final double gstAmount = totalAmount - baseAmount;

    final formattedBaseAmount = baseAmount.toStringAsFixed(2);
    final formattedGstAmount = gstAmount.toStringAsFixed(2);
    final formattedTotalAmount = totalAmount.toStringAsFixed(2);

    String displayPaymentMethod;
    switch (subscription.paymentMethod.toLowerCase()) {
      case 'android':
        displayPaymentMethod = 'Google Play Store';
        break;
      case 'ios':
        displayPaymentMethod = 'Apple Store';
        break;
      case 'razorpay':
        displayPaymentMethod = 'Razorpay';
        break;
      default:
        displayPaymentMethod = subscription.paymentMethod;
    }

    final customPageFormat = PdfPageFormat((595 + 842) / 2, (842 + 1191) / 2);

    pdf.addPage(
      pw.Page(
        pageFormat: customPageFormat,
        build: (pw.Context context) {
          return pw.Padding(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 42, vertical: 50),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue900,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SUBSCRIPTION INVOICE',
                          style: pw.TextStyle(
                              fontSize: 28,
                              wordSpacing: 2,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white)),
                      pw.SizedBox(height: 10),
                      pw.Text('Invoice Number: $invoiceNumber',
                          style: const pw.TextStyle(
                              fontSize: 14, color: PdfColors.white)),
                      pw.SizedBox(height: 7),
                      pw.Text(
                          'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                          style: const pw.TextStyle(
                              fontSize: 14, color: PdfColors.white)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.max,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('FROM:',
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.grey600)),
                            pw.SizedBox(height: 5),
                            pw.Text('Videos Alarm',
                                style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(
                                'Shree Palace, 11 Ananya Vihar,\nAdj Doon South Apartments, Sewla Chowk'),
                            pw.Text(
                                'GMS Road, Dehradun, Uttarakhand, India'),
                            pw.Text('Email: info@videosalarm.com'),
                            pw.Text('GSTIN: 05AADCC3324K1ZX'),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO:',
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey600)),
                          pw.SizedBox(height: 5),
                          pw.Text(subscription.name,
                              style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text('Phone: ${subscription.phone}'),
                          if (subscription.purchaseDate != 'N/A')
                            pw.Text(
                                'Purchase Date: ${subscription.purchaseDate}'),
                          if (subscription.transactionId.isNotEmpty)
                            pw.Text(
                                'Transaction ID: ${subscription.transactionId}'),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    children: [
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text('Description',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text('Plan Type',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text('Payment Method',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text('Amount',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold),
                                  textAlign: pw.TextAlign.right)),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(
                                  '${subscription.planName} Subscription')),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(subscription.planName)),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(displayPaymentMethod)),
                          pw.Padding(
                              padding: const pw.EdgeInsets.all(10),
                              child: pw.Text(formattedBaseAmount,
                                  textAlign: pw.TextAlign.right)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal:',
                                style: const pw.TextStyle(fontSize: 12)),
                            pw.Text(formattedBaseAmount,
                                style: const pw.TextStyle(fontSize: 12)),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('GST (18%):',
                                style: const pw.TextStyle(fontSize: 12)),
                            pw.Text(formattedGstAmount,
                                style: const pw.TextStyle(fontSize: 12)),
                          ],
                        ),
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total:',
                                style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.Text(formattedTotalAmount,
                                style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: subscription.paymentStatus == 'Success'
                        ? PdfColors.green100
                        : PdfColors.red100,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('Payment Status: ',
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: subscription.paymentStatus == 'Success'
                                  ? PdfColors.green800
                                  : PdfColors.red800)),
                      pw.Text(subscription.paymentStatus,
                          style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: subscription.paymentStatus == 'Success'
                                  ? PdfColors.green800
                                  : PdfColors.red800)),
                    ],
                  ),
                ),
                if (subscription.expiryDate != 'N/A') ...[
                  pw.SizedBox(height: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue100,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text('Subscription Expires: ',
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800)),
                        pw.Text(subscription.expiryDate,
                            style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800)),
                      ],
                    ),
                  ),
                ],
                pw.SizedBox(height: 15),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                  child: pw.Text('Terms & Conditions',
                      style: pw.TextStyle(
                          color: PdfColors.blue900,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 3),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14),
                  child: pw.Text(
                    'By purchasing a subscription to VideosAlarm, you agree to our Terms and Conditions, Privacy Policy, and Cancellation & Refund Policy.',
                    style: pw.TextStyle(
                        color: PdfColors.grey700,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Spacer(),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Thank you for your business!',
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 5),
                      pw.Text(
                          'For any queries, please contact info@videosalarm.com',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<void> migrateToSubscriptionCollection() async {
    _showLoadingDialog('Migrating subscription data...');
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot usersSnapshot = await firestore.collection('users').get();
      const batchSize = 500;
      final docs = usersSnapshot.docs;
      int totalMigrated = 0;

      for (int i = 0; i < docs.length; i += batchSize) {
        final batch = firestore.batch();
        final chunk = docs.skip(i).take(batchSize);

        for (var doc in chunk) {
          final data = doc.data() as Map<String, dynamic>;
          final bool isTestRecord = data['test'] ?? false;

          if (data['test'] == true) {
            Map<String, dynamic> subscriptionData = {
              'userId': doc.id,
              'name': data['name'] ?? 'Unknown',
              'phone': data['phone'] ?? 'Unknown',
              'subscriptionType': data['SubscriptionType'] ?? '',
              'purchaseToken': data['PurchaseToken'] ?? '',
              'active': data['Active'] ?? false,
              'test': isTestRecord,
              'paymentStatus':
                  data['PaymentStatus'] ?? _determinePaymentStatus(data),
              'backendPaymentStatus':
                  data['BackendPaymentStatus'] ?? 'Unknown',
              'paymentMethod':
                  data['paymentMethod'] ?? _determinePaymentMethod(data),
              'subscriptionStartDate': data['SubscriptionStartDate'],
              'subscriptionExpiryDate': data['SubscriptionExpiryDate'],
              'updatedAt': data['updatedAt'] ?? FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
              'devices': data['devices'] ?? {},
              'planPrice': _getPlanPrice(data['SubscriptionType'] ?? ''),
              'planName': _getPlanName(data['SubscriptionType'] ?? ''),
              'razorpayOrderId': data['razorpayOrderId'],
              'razorpayPaymentId': data['razorpayPaymentId'],
              'razorpaySignature': data['razorpaySignature'],
              'transactionId': data['transactionId'],
              'receiptUrl': data['receiptUrl'],
            };
            subscriptionData.removeWhere((key, value) => value == null);
            DocumentReference subscriptionRef =
                firestore.collection('subscription').doc(doc.id);
            batch.set(subscriptionRef, subscriptionData);
            totalMigrated++;
          } else {
            if (data.containsKey('SubscriptionType') ||
                data.containsKey('PurchaseToken')) {
              Map<String, dynamic> subscriptionData = {
                'userId': doc.id,
                'name': data['name'] ?? 'Unknown',
                'phone': data['phone'] ?? 'Unknown',
                'subscriptionType': data['SubscriptionType'] ?? '',
                'purchaseToken': data['PurchaseToken'] ?? '',
                'active': data['Active'] ?? false,
                'test': isTestRecord,
                'paymentStatus':
                    data['PaymentStatus'] ?? _determinePaymentStatus(data),
                'backendPaymentStatus':
                    data['BackendPaymentStatus'] ?? 'Unknown',
                'paymentMethod':
                    data['paymentMethod'] ?? _determinePaymentMethod(data),
                'subscriptionStartDate': data['SubscriptionStartDate'],
                'subscriptionExpiryDate': data['SubscriptionExpiryDate'],
                'updatedAt': data['updatedAt'] ?? FieldValue.serverTimestamp(),
                'createdAt': FieldValue.serverTimestamp(),
                'devices': data['devices'] ?? {},
                'planPrice': _getPlanPrice(data['SubscriptionType'] ?? ''),
                'planName': _getPlanName(data['SubscriptionType'] ?? ''),
                'razorpayOrderId': data['razorpayOrderId'],
                'razorpayPaymentId': data['razorpayPaymentId'],
                'razorpaySignature': data['razorpaySignature'],
                'transactionId': data['transactionId'],
                'receiptUrl': data['receiptUrl'],
              };
              subscriptionData.removeWhere((key, value) => value == null);
              DocumentReference subscriptionRef =
                  firestore.collection('subscription').doc(doc.id);
              batch.set(subscriptionRef, subscriptionData);
              totalMigrated++;
            }
          }
        }
        await batch.commit();
      }

      Navigator.of(context).pop();
      _showSuccessSnackBar('Successfully migrated $totalMigrated records');
      await loadSubscriptions();
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Migration failed: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _determinePaymentStatus(Map<String, dynamic> data) {
    if (data.containsKey('PaymentStatus')) {
      return data['PaymentStatus'];
    } else if (data.containsKey('Active') && data['Active'] == true) {
      return 'Success';
    } else if (data.containsKey('PurchaseToken') &&
        data['PurchaseToken'].toString().isNotEmpty) {
      return 'Pending';
    } else {
      return 'Failed';
    }
  }

  String _determinePaymentMethod(Map<String, dynamic> data) {
    if (data.containsKey('paymentMethod')) return data['paymentMethod'];
    final subscriptionType = data['SubscriptionType'];
    final purchaseToken = data['PurchaseToken']?.toString();
    if (subscriptionType == 'com.videosalarm.subscription.premium') {
      return 'iOS';
    } else if (subscriptionType == 'vip_plan_id') {
      if (purchaseToken != null && purchaseToken.startsWith('pay_')) {
        return 'Razorpay';
      } else {
        return 'Android';
      }
    } else {
      return 'Unknown';
    }
  }

  List<UserSubscription> get filteredSubscriptions {
    return subscriptions.where((subscription) {
      final matchesSearch = subscription.name
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          subscription.phone.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesStatus =
          statusFilter == 'All' || subscription.paymentStatus == statusFilter;
      final matchesBackendStatus = backendStatusFilter == 'All' ||
          subscription.backendPaymentStatus.toLowerCase() ==
              backendStatusFilter.toLowerCase();
      final matchesPaymentMethod = paymentMethodFilter == 'All' ||
          subscription.paymentMethod.toLowerCase() ==
              paymentMethodFilter.toLowerCase();
      bool matchesDateRange = true;
      if (isDateFilterActive && selectedDateRange != null) {
        if (subscription.purchaseDateTime != null) {
          final purchaseDate = subscription.purchaseDateTime!;
          matchesDateRange = (purchaseDate.isAfter(selectedDateRange!.start) ||
                  purchaseDate
                      .isAtSameMomentAs(selectedDateRange!.start)) &&
              (purchaseDate.isBefore(
                      selectedDateRange!.end.add(const Duration(days: 1))) ||
                  purchaseDate.isAtSameMomentAs(selectedDateRange!.end));
        } else {
          matchesDateRange = false;
        }
      }
      return matchesSearch &&
          matchesStatus &&
          matchesBackendStatus &&
          matchesPaymentMethod &&
          matchesDateRange;
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.input,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );
    if (picked != null && picked != selectedDateRange) {
      setState(() => selectedDateRange = picked);
      _generateFilteredPdf();
    }
  }

  Future<void> _selectDateRangeForFilter() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.input,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.blue.shade400,
              onPrimary: Colors.white,
              surface: const Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
        isDateFilterActive = true;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      selectedDateRange = null;
      isDateFilterActive = false;
    });
  }

  Widget _buildDateFilterChip() {
    if (!isDateFilterActive || selectedDateRange == null) {
      return const SizedBox.shrink();
    }
    final startDate =
        DateFormat('dd MMM yyyy').format(selectedDateRange!.start);
    final endDate = DateFormat('dd MMM yyyy').format(selectedDateRange!.end);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.date_range, color: Colors.blue.shade300, size: 18),
          const SizedBox(width: 8),
          Text('Filter: $startDate - $endDate',
              style: TextStyle(
                  color: Colors.blue.shade300,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          InkWell(
              onTap: _clearDateFilter,
              child:
                  Icon(Icons.close, color: Colors.blue.shade300, size: 18)),
        ],
      ),
    );
  }

  Future<void> _generateFilteredPdf() async {
    if (selectedDateRange == null) {
      _showErrorSnackBar('Please select a date range first.');
      return;
    }
    final filtered = subscriptions.where((sub) {
      if (sub.purchaseDateTime == null) return false;
      final purchaseDate = sub.purchaseDateTime!;
      return (purchaseDate.isAfter(selectedDateRange!.start) ||
              purchaseDate.isAtSameMomentAs(selectedDateRange!.start)) &&
          (purchaseDate.isBefore(selectedDateRange!.end) ||
              purchaseDate.isAtSameMomentAs(selectedDateRange!.end));
    }).toList();
    final startDate =
        DateFormat('yyyy-MM-dd').format(selectedDateRange!.start);
    final endDate = DateFormat('yyyy-MM-dd').format(selectedDateRange!.end);
    await createPdf(filtered, 'Subscriptions from $startDate to $endDate');
  }

  Future<void> createPdf(List<UserSubscription> data, String title) async {
    _showLoadingDialog('Generating PDF...');
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Table.fromTextArray(
                headerStyle:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: [
                  'Name',
                  'Phone',
                  'Plan',
                  'Price',
                  'Payment Status',
                  'Method',
                  'Expiry'
                ],
                data: data
                    .map((sub) => [
                          sub.name,
                          sub.phone,
                          sub.planName,
                          sub.price,
                          sub.paymentStatus,
                          sub.paymentMethod,
                          sub.expiryDate
                        ])
                    .toList(),
              ),
            ];
          },
        ),
      );
      final bytes = await pdf.save();
      Navigator.of(context).pop();
      if (kIsWeb) {
        await Printing.sharePdf(
            bytes: bytes, filename: 'subscriptions_report.pdf');
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file =
            File('${directory.path}/subscriptions_report.pdf');
        await file.writeAsBytes(bytes);
        await Printing.sharePdf(
            bytes: bytes, filename: 'subscriptions_report.pdf');
      }
      _showSuccessSnackBar('PDF generated successfully');
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Error generating PDF: $e');
    }
  }

  Future<void> _exportToExcel(
      List<UserSubscription> data, String title) async {
    _showLoadingDialog('Generating Excel file...');
    try {
      final excel = Excel.createExcel();
      final Sheet sheetObject = excel[title];
      List<String> headers = [
        'User ID',
        'Name',
        'Phone',
        'Plan Name',
        'Price',
        'Payment Status',
        'Backend Status',
        'Payment Method',
        'Purchase Date',
        'Expiry Date',
        'Is Active',
        'Purchase Token'
      ];
      sheetObject
          .appendRow(headers.map((h) => TextCellValue(h)).toList());
      for (var subscription in data) {
        sheetObject.appendRow([
          TextCellValue(subscription.userId),
          TextCellValue(subscription.name),
          TextCellValue(subscription.phone),
          TextCellValue(subscription.planName),
          TextCellValue(subscription.price),
          TextCellValue(subscription.paymentStatus),
          TextCellValue(subscription.backendPaymentStatus),
          TextCellValue(subscription.paymentMethod),
          TextCellValue(subscription.purchaseDate),
          TextCellValue(subscription.expiryDate),
          TextCellValue(subscription.isActive.toString()),
          TextCellValue(subscription.purchaseToken),
        ]);
      }
      Navigator.of(context).pop();
      final String fileName =
          'Subscriptions_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      var fileBytes = excel.save();
      if (fileBytes != null) {
        if (!kIsWeb) {
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/$fileName';
          final file = File(path);
          await file.writeAsBytes(fileBytes, flush: true);
          _showSuccessSnackBar('Excel file saved to Downloads');
        } else {
          excel.save(fileName: fileName);
          _showSuccessSnackBar('Excel file is being downloaded.');
        }
      } else {
        _showErrorSnackBar('Failed to generate Excel file.');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorSnackBar('Error generating Excel file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildInfoBanner(),
          _buildFilters(),
          _buildStatsCards(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1A1A1A),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Subscription Analytics',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
        ],
      ),
      actions: [
        _buildActionButton(
          icon: Icons.table_chart_outlined,
          label: 'Excel',
          onPressed: () => _exportToExcel(
              filteredSubscriptions, 'Filtered Subscriptions'),
          tooltip: 'Export to Excel',
          color: Colors.green.shade400,
        ),
        _buildActionButton(
          icon: Icons.picture_as_pdf_outlined,
          label: 'PDF',
          onPressed: () => createPdf(
              subscriptions
                  .where((s) =>
                      s.backendPaymentStatus.toLowerCase() == 'active')
                  .toList(),
              'Active Subscriptions Report'),
          tooltip: 'Generate PDF Report',
          color: Colors.red.shade400,
        ),
        _buildActionButton(
          icon: Icons.date_range,
          label: 'Date PDF',
          onPressed: _selectDateRange,
          tooltip: 'Generate PDF by Date Range',
          color: Colors.orange.shade400,
        ),
        _buildActionButton(
          icon: Icons.cloud_sync_outlined,
          label: 'Migrate',
          onPressed: migrateToSubscriptionCollection,
          tooltip: 'Migrate Data',
          color: Colors.cyan.shade400,
        ),
        _buildActionButton(
          icon: Icons.refresh,
          label: 'Refresh',
          onPressed: loadSubscriptions,
          tooltip: 'Refresh Data',
          color: Colors.blue.shade400,
        ),
        _buildActionButton(
          icon: isGridView ? Icons.table_rows : Icons.grid_view,
          label: isGridView ? 'Table' : 'Grid',
          onPressed: () => setState(() => isGridView = !isGridView),
          tooltip: isGridView ? 'Table View' : 'Grid View',
          color: Colors.purple.shade400,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: tooltip,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: 18),
          label: Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1)
          ]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.info_outline,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Use the sync button to migrate subscription data to the dedicated collection for better organization.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                ElevatedButton.icon(
                  onPressed: _selectDateRangeForFilter,
                  icon: Icon(
                      isDateFilterActive
                          ? Icons.filter_alt
                          : Icons.filter_alt_outlined,
                      size: 18),
                  label: Text(
                      isDateFilterActive
                          ? 'Change Dates'
                          : 'Filter by Date',
                      style: const TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDateFilterActive
                        ? Colors.blue.shade600
                        : const Color(0xFF2A2A2A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            _buildDateFilterChip(),
            const SizedBox(height: 16),
            _buildSearchField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildDropdownFilter(
                        'Payment Status',
                        statusFilter,
                        statusOptions,
                        (v) => setState(() => statusFilter = v!))),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDropdownFilter(
                        'Backend Status',
                        backendStatusFilter,
                        backendStatusOptions,
                        (v) =>
                            setState(() => backendStatusFilter = v!))),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDropdownFilter(
                        'Payment Method',
                        paymentMethodFilter,
                        paymentMethodOptions,
                        (v) =>
                            setState(() => paymentMethodFilter = v!))),
              ],
            ),
            if (isDateFilterActive ||
                statusFilter != 'All' ||
                backendStatusFilter != 'All' ||
                paymentMethodFilter != 'All' ||
                searchQuery.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                      'Showing ${filteredSubscriptions.length} of ${subscriptions.length} records',
                      style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        searchQuery = '';
                        statusFilter = 'All';
                        backendStatusFilter = 'All';
                        paymentMethodFilter = 'All';
                        _clearDateFilter();
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear All Filters',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.orange.shade400),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12)),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search by name or phone...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[500]),
                  onPressed: () => setState(() => searchQuery = ''))
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (value) => setState(() => searchQuery = value),
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String value,
      List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonFormField<String>(
            value: value,
            style: const TextStyle(color: Colors.white),
            dropdownColor: const Color(0xFF2A2A2A),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: options
                .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(o,
                        style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return SliverToBoxAdapter(
      child: Container(
        height: 120,
        margin: const EdgeInsets.all(16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildStatCard(
                'Success',
                subscriptions
                    .where((s) => s.paymentStatus == 'Success')
                    .length
                    .toString(),
                Icons.check_circle,
                Colors.green),
            _buildStatCard(
                'Failed',
                subscriptions
                    .where((s) => s.paymentStatus == 'Failed')
                    .length
                    .toString(),
                Icons.error,
                Colors.red),
            _buildStatCard(
                'Active',
                subscriptions
                    .where((s) =>
                        s.backendPaymentStatus.toLowerCase() == 'active')
                    .length
                    .toString(),
                Icons.verified,
                Colors.teal),
            _buildStatCard(
                'iOS',
                subscriptions
                    .where(
                        (s) => s.paymentMethod.toLowerCase() == 'ios')
                    .length
                    .toString(),
                Icons.phone_iphone,
                Colors.purple),
            _buildStatCard(
                'Android',
                subscriptions
                    .where((s) =>
                        s.paymentMethod.toLowerCase() == 'android')
                    .length
                    .toString(),
                Icons.android,
                Colors.orange),
            _buildStatCard(
                'Razorpay',
                subscriptions
                    .where((s) =>
                        s.paymentMethod.toLowerCase() == 'razorpay')
                    .length
                    .toString(),
                Icons.payment,
                Colors.cyan),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          Text(title,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(height: 16),
              Text('Loading subscriptions...',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }
    return isGridView ? _buildGridView() : _buildTableView();
  }

  Widget _buildGridView() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              _buildSubscriptionCard(filteredSubscriptions[index]),
          childCount: filteredSubscriptions.length,
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(UserSubscription subscription) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      _getStatusColor(subscription.paymentStatus)
                          .withOpacity(0.2),
                  child: Text(
                    subscription.name.isNotEmpty
                        ? subscription.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color:
                            _getStatusColor(subscription.paymentStatus),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subscription.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(subscription.phone,
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCardRow('Plan', subscription.planName),
            _buildCardRow('Price', subscription.price),
            _buildCardRow('Method', subscription.paymentMethod),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(subscription.paymentStatus,
                    _getStatusColor(subscription.paymentStatus)),
                const SizedBox(width: 8),
                _buildStatusChip(
                    subscription.backendPaymentStatus,
                    _getBackendStatusColor(
                        subscription.backendPaymentStatus)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTableView() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              width: 1700,
              padding: const EdgeInsets.all(16),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: DataTableThemeData(
                    headingRowColor: MaterialStateProperty.all(
                        const Color(0xFF2A2A2A)),
                    dataRowColor:
                        MaterialStateProperty.all(Colors.transparent),
                    dividerThickness: 0.5,
                  ),
                ),
                child: DataTable(
                  columnSpacing: 16,
                  headingRowHeight: 56,
                  dataRowHeight: 64,
                  headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14),
                  dataTextStyle: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                  columns: const [
                    DataColumn(
                        label: SizedBox(
                            width: 120,
                            child: Text('Purchase Date'))),
                    DataColumn(
                        label: SizedBox(
                            width: 140, child: Text('Customer'))),
                    DataColumn(
                        label:
                            SizedBox(width: 120, child: Text('Phone'))),
                    DataColumn(
                        label:
                            SizedBox(width: 100, child: Text('Plan'))),
                    DataColumn(
                        label:
                            SizedBox(width: 80, child: Text('Price'))),
                    DataColumn(
                        label: SizedBox(
                            width: 120,
                            child: Text('Payment Status'))),
                    // 👇 Backend Status column — now editable via dropdown
                    DataColumn(
                        label: SizedBox(
                            width: 160,
                            child: Text('Backend Status'))),
                    DataColumn(
                        label:
                            SizedBox(width: 120, child: Text('Method'))),
                    DataColumn(
                        label: SizedBox(
                            width: 120, child: Text('Expiry Date'))),
                  ],
                  rows: filteredSubscriptions.map((subscription) {
                    return DataRow(cells: [
                      DataCell(SizedBox(
                          width: 120,
                          child: Text(subscription.purchaseDate,
                              style: const TextStyle(
                                  color: Colors.white70)))),
                      DataCell(SizedBox(
                        width: 140,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _getStatusColor(
                                      subscription.paymentStatus)
                                  .withOpacity(0.2),
                              child: Text(
                                subscription.name.isNotEmpty
                                    ? subscription.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    color: _getStatusColor(
                                        subscription.paymentStatus),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(subscription.name,
                                    style: const TextStyle(
                                        color: Colors.white),
                                    overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      )),
                      DataCell(SizedBox(
                          width: 120,
                          child: Text(subscription.phone,
                              style: const TextStyle(
                                  color: Colors.white70)))),
                      DataCell(SizedBox(
                        width: 100,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('Premium',
                              style: TextStyle(
                                  color: Colors.blue.shade300,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center),
                        ),
                      )),
                      DataCell(SizedBox(
                          width: 80,
                          child: Text(subscription.price,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)))),
                      DataCell(SizedBox(
                          width: 120,
                          child: _buildEnhancedStatusChip(
                              subscription.paymentStatus,
                              _getStatusColor(
                                  subscription.paymentStatus)))),

                      // 👇 Editable Backend Status dropdown
                      DataCell(SizedBox(
                        width: 160,
                        child: _buildBackendStatusDropdown(subscription),
                      )),

                      DataCell(SizedBox(
                          width: 120,
                          child: _buildMethodChip(
                              subscription.paymentMethod))),
                      DataCell(SizedBox(
                          width: 120,
                          child: Text(subscription.expiryDate,
                              style: const TextStyle(
                                  color: Colors.white70)))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Inline dropdown to update BackendPaymentStatus in Firestore `users` collection
  Widget _buildBackendStatusDropdown(UserSubscription subscription) {
    // Normalize current value to match our options list
    String currentValue = subscription.backendPaymentStatus;
    if (!backendStatusEditOptions.contains(currentValue)) {
      currentValue = 'Unknown';
    }

    final color = _getBackendStatusColor(currentValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        //border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isDense: true,
          dropdownColor: const Color(0xFF2A2A2A),
          iconEnabledColor: color,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600),
          items: backendStatusEditOptions
              .map((option) => DropdownMenuItem(
                    value: option,
                    child: Row(
                      children: [
                        Icon(_getBackendStatusIcon(option),
                            color: _getBackendStatusColor(option),
                            size: 14),
                        const SizedBox(width: 6),
                        Text(option,
                            style: TextStyle(
                                color: _getBackendStatusColor(option),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (newValue) {
            if (newValue != null && newValue != currentValue) {
              _updateBackendStatus(subscription, newValue);
            }
          },
        ),
      ),
    );
  }

  IconData _getBackendStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'expired':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Widget _buildEnhancedStatusChip(String status, Color color) {
    IconData icon;
    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
        icon = Icons.check_circle;
        break;
      case 'failed':
      case 'inactive':
        icon = Icons.error;
        break;
      case 'pending':
        icon = Icons.schedule;
        break;
      case 'cancelled':
      case 'aborted':
        icon = Icons.cancel;
        break;
      default:
        icon = Icons.help;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(status,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMethodChip(String method) {
    IconData icon;
    Color color;
    switch (method.toLowerCase()) {
      case 'ios':
        icon = Icons.phone_iphone;
        color = Colors.purple;
        break;
      case 'android':
        icon = Icons.android;
        color = Colors.green;
        break;
      case 'razorpay':
        icon = Icons.payment;
        color = Colors.blue;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(method,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'aborted':
      case 'cancelled':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getBackendStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String _getPlanName(String subscriptionType) {
    switch (subscriptionType) {
      case 'vip_plan_id':
        return 'VIP Plan';
      case 'com.videosalarm.subscription.premium':
        return 'Premium Plan';
      default:
        return 'Premium Plan';
    }
  }

  static String _getPlanPrice(String subscriptionType) {
    switch (subscriptionType) {
      case 'vip_plan_id':
      case 'com.videosalarm.subscription.premium':
        return '₹99.00';
      default:
        return '₹99.00';
    }
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────

class UserSubscription {
  final String userId;
  final String name;
  final String phone;
  final String subscriptionType;
  final String planName;
  final String price;
  final String paymentStatus;
  final String backendPaymentStatus;
  final String paymentMethod;
  final String purchaseToken;
  final String purchaseDate;
  final DateTime? purchaseDateTime;
  final String expiryDate;
  final bool isActive;
  final bool isTest;
  final String transactionId;
  final Map<String, dynamic>? devices;

  UserSubscription({
    required this.userId,
    required this.name,
    required this.phone,
    required this.subscriptionType,
    required this.planName,
    required this.price,
    required this.paymentStatus,
    required this.backendPaymentStatus,
    required this.paymentMethod,
    required this.purchaseToken,
    required this.purchaseDate,
    required this.purchaseDateTime,
    required this.expiryDate,
    required this.isActive,
    required this.isTest,
    required this.transactionId,
    this.devices,
  });

  /// Creates a copy with updated fields (used for local state update)
  UserSubscription copyWith({String? backendPaymentStatus}) {
    return UserSubscription(
      userId: userId,
      name: name,
      phone: phone,
      subscriptionType: subscriptionType,
      planName: planName,
      price: price,
      paymentStatus: paymentStatus,
      backendPaymentStatus:
          backendPaymentStatus ?? this.backendPaymentStatus,
      paymentMethod: paymentMethod,
      purchaseToken: purchaseToken,
      purchaseDate: purchaseDate,
      purchaseDateTime: purchaseDateTime,
      expiryDate: expiryDate,
      isActive: isActive,
      isTest: isTest,
      transactionId: transactionId,
      devices: devices,
    );
  }

  factory UserSubscription.fromSubscriptionCollection(
      String documentId, Map<String, dynamic> data) {
    final subscriptionType = data['subscriptionType'] ?? '';
    final planName = _getPlanName(subscriptionType);
    final price = data['planPrice'] ?? _getPlanPrice(subscriptionType);
    String paymentStatus = data['paymentStatus'] ?? 'Unknown';
    String backendPaymentStatus =
        data['backendPaymentStatus'] ?? 'Unknown';
    if (backendPaymentStatus != 'Unknown') {
      backendPaymentStatus =
          backendPaymentStatus.substring(0, 1).toUpperCase() +
              backendPaymentStatus.substring(1).toLowerCase();
    }

    String paymentMethod = data['paymentMethod'] ?? 'Unknown';
    if (paymentMethod != 'Unknown') {
      switch (paymentMethod.toLowerCase()) {
        case 'ios':
          paymentMethod = 'iOS';
          break;
        case 'android':
          paymentMethod = 'Android';
          break;
        case 'razorpay':
          paymentMethod = 'Razorpay';
          break;
        default:
          paymentMethod = paymentMethod.substring(0, 1).toUpperCase() +
              paymentMethod.substring(1).toLowerCase();
      }
    }

    String purchaseDate = 'N/A';
    DateTime? purchaseDateTime;
    String expiryDate = 'N/A';

    if (data.containsKey('subscriptionStartDate') &&
        data['subscriptionStartDate'] != null) {
      final startDate =
          (data['subscriptionStartDate'] as Timestamp).toDate();
      purchaseDate =
          DateFormat('yyyy-MM-dd HH:mm').format(startDate);
      purchaseDateTime = startDate;
    }

    if (data.containsKey('subscriptionExpiryDate') &&
        data['subscriptionExpiryDate'] != null) {
      final expiry =
          (data['subscriptionExpiryDate'] as Timestamp).toDate();
      expiryDate = DateFormat('yyyy-MM-dd HH:mm').format(expiry);
    }

    return UserSubscription(
      userId: data['userId'] ?? documentId,
      name: data['name'] ?? 'Unknown',
      phone: data['phone'] ?? 'Unknown',
      subscriptionType: subscriptionType,
      planName: planName,
      price: price,
      paymentStatus: paymentStatus,
      backendPaymentStatus: backendPaymentStatus,
      paymentMethod: paymentMethod,
      purchaseToken: data['purchaseToken'] ?? '',
      purchaseDate: purchaseDate,
      purchaseDateTime: purchaseDateTime,
      expiryDate: expiryDate,
      isActive: data['active'] ?? false,
      isTest: data['test'] ?? false,
      transactionId: data['transactionId'] ?? '',
      devices: data['devices'] is Map<String, dynamic>
          ? data['devices'] as Map<String, dynamic>?
          : data['devices'] is List
              ? (data['devices'] as List)
                  .asMap()
                  .map((k, v) => MapEntry(k.toString(), v))
              : null,
    );
  }

  factory UserSubscription.fromFirestore(
      String userId, Map<String, dynamic> data) {
    final subscriptionType = data['SubscriptionType'] ?? '';
    final planName = _getPlanName(subscriptionType);
    final price = _getPlanPrice(subscriptionType);
    String paymentStatus = 'Unknown';
    if (data.containsKey('PaymentStatus')) {
      paymentStatus = data['PaymentStatus'];
    } else if (data.containsKey('Active') && data['Active'] == true) {
      paymentStatus = 'Success';
    } else if (data.containsKey('PurchaseToken') &&
        data['PurchaseToken'].toString().isNotEmpty) {
      paymentStatus = 'Pending';
    } else {
      paymentStatus = 'Failed';
    }
    String backendPaymentStatus = 'Unknown';
    if (data.containsKey('BackendPaymentStatus')) {
      backendPaymentStatus = data['BackendPaymentStatus'].toString();
      backendPaymentStatus =
          backendPaymentStatus.substring(0, 1).toUpperCase() +
              backendPaymentStatus.substring(1).toLowerCase();
    }

    String paymentMethod = 'Unknown';
    if (data.containsKey('paymentMethod')) {
      paymentMethod = data['paymentMethod'].toString();
      switch (paymentMethod.toLowerCase()) {
        case 'ios':
          paymentMethod = 'iOS';
          break;
        case 'android':
          paymentMethod = 'Android';
          break;
        case 'razorpay':
          paymentMethod = 'Razorpay';
          break;
        default:
          paymentMethod = paymentMethod.substring(0, 1).toUpperCase() +
              paymentMethod.substring(1).toLowerCase();
      }
    }

    String purchaseDate = 'N/A';
    DateTime? purchaseDateTime;
    String expiryDate = 'N/A';

    if (data.containsKey('SubscriptionStartDate')) {
      final startDate =
          (data['SubscriptionStartDate'] as Timestamp).toDate();
      purchaseDate =
          DateFormat('yyyy-MM-dd HH:mm').format(startDate);
      purchaseDateTime = startDate;
    }

    if (data.containsKey('SubscriptionExpiryDate')) {
      final expiry =
          (data['SubscriptionExpiryDate'] as Timestamp).toDate();
      expiryDate = DateFormat('yyyy-MM-dd HH:mm').format(expiry);
    }

    return UserSubscription(
      userId: userId,
      name: data['name'] ?? 'Unknown',
      phone: data['phone'] ?? 'Unknown',
      subscriptionType: subscriptionType,
      planName: planName,
      price: price,
      paymentStatus: paymentStatus,
      backendPaymentStatus: backendPaymentStatus,
      paymentMethod: paymentMethod,
      purchaseToken: data['PurchaseToken'] ?? '',
      purchaseDate: purchaseDate,
      purchaseDateTime: purchaseDateTime,
      expiryDate: expiryDate,
      isActive: data['Active'] ?? false,
      isTest: data['test'] ?? false,
      transactionId: data['transactionId'] ?? '',
      devices: data['devices'] is Map<String, dynamic>
          ? data['devices'] as Map<String, dynamic>?
          : data['devices'] is List
              ? (data['devices'] as List)
                  .asMap()
                  .map((k, v) => MapEntry(k.toString(), v))
              : null,
    );
  }

  static String _getPlanName(String subscriptionType) {
    switch (subscriptionType) {
      case 'vip_plan_id':
        return 'VIP Plan';
      case 'com.videosalarm.subscription.premium':
        return 'Premium Plan';
      default:
        return 'Premium Plan';
    }
  }

  static String _getPlanPrice(String subscriptionType) {
    switch (subscriptionType) {
      case 'vip_plan_id':
      case 'com.videosalarm.subscription.premium':
        return '₹99.00';
      default:
        return '₹99.00';
    }
  }
}
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class SubscriptionService {
  // Replace with your real values
  static const _razorpayKeyId = 'rzp_live_noJNXCxQIlWIgH';
  static const _razorpayKeySecret = '3qPSMuQzCxYZQpAH1czTB8AB';
  static const _iosSharedSecret = 'fde1c8b51a044cd78dbe1bfa073dd77f';
  static const _androidEndpoint = 'http://165.22.215.103:3066/checkSubscriptionStatus';

  /// Entry point: Validate all users in Firestore
  Future<void> validateAllUsers() async {
    final usersCollection = FirebaseFirestore.instance.collection('users');
    final usersSnapshot = await usersCollection.get();

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final String docId = doc.id;

      final String? paymentMethod = data['paymentMethod'];
      final String? purchaseToken = data['PurchaseToken'];
      final String productId = data['SubscriptionType'] ?? 'vip_monthly';

      if (paymentMethod == null || purchaseToken == null || purchaseToken.isEmpty) continue;

      String backendStatus = 'unknown';

      try {
        switch (paymentMethod.toLowerCase()) {
          case 'android':
            backendStatus = await _checkAndroidSubscription(purchaseToken, productId);
            break;
          case 'ios':
            backendStatus = await _checkIosReceipt(purchaseToken, productId);
            break;
          case 'razorpay':
            backendStatus = await _checkRazorpayPaymentStatus(purchaseToken);
            break;
          default:
            backendStatus = 'unsupported';
        }
      } catch (e) {
        print('❌ Error validating $docId: $e');
        backendStatus = 'exception';
      }

      await usersCollection.doc(docId).update({
        'BackendPaymentStatus': backendStatus,
        'lastChecked': DateTime.now(),
      });

      print('✅ Updated $docId → $backendStatus');
    }

    print('🎉 All users validated.');
  }

  /// Android subscription check via your backend
  Future<String> _checkAndroidSubscription(String purchaseToken, String productId) async {
    final response = await http.post(
      Uri.parse(_androidEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'purchaseToken': purchaseToken, 'productId': productId}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'Success') {
        final isActive = result['paymentState'] == 1 && result['canceled'] == false;
        return isActive ? 'active' : 'inactive';
      } else {
        return 'error';
      }
    } else {
      return 'api_error';
    }
  }

  /// iOS subscription check (production → fallback to sandbox)
  Future<String> _checkIosReceipt(String receiptData, String productId) async {
    bool isValid = await _validateIosReceipt(receiptData, productId, isSandbox: false);
    if (!isValid) {
      isValid = await _validateIosReceipt(receiptData, productId, isSandbox: true);
    }
    return isValid ? 'active' : 'inactive';
  }

  /// Apple iTunes receipt validator
  Future<bool> _validateIosReceipt(String receiptData, String productId, {required bool isSandbox}) async {
    final url = isSandbox
        ? "https://sandbox.itunes.apple.com/verifyReceipt"
        : "https://buy.itunes.apple.com/verifyReceipt";

    final requestBody = {
      'receipt-data': receiptData,
      'password': _iosSharedSecret,
      'exclude-old-transactions': true,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) return false;

      final result = jsonDecode(response.body);

      if (result['status'] == 0) {
        final inAppPurchases = result['latest_receipt_info'] ?? [];

        for (final purchase in inAppPurchases) {
          if (purchase['product_id'] == productId) {
            final expiresDateMs = int.tryParse(purchase['expires_date_ms'] ?? '0') ?? 0;
            final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresDateMs);
            if (expiryDate.isAfter(DateTime.now())) return true;
          }
        }
      } else if (result['status'] == 21007 && !isSandbox) {
        return _validateIosReceipt(receiptData, productId, isSandbox: true);
      }
    } catch (e) {
      print("❌ iOS validation error (${isSandbox ? 'sandbox' : 'prod'}): $e");
    }

    return false;
  }

  /// Razorpay payment check
  Future<String> _checkRazorpayPaymentStatus(String paymentId) async {
    final authHeader = base64Encode(utf8.encode('$_razorpayKeyId:$_razorpayKeySecret'));

    try {
      final response = await http.get(
        Uri.parse('https://api.razorpay.com/v1/payments/$paymentId'),
        headers: {'Authorization': 'Basic $authHeader'},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final status = result['status'];
        return status == 'captured' ? 'active' : 'inactive';
      } else {
        print("❌ Razorpay error ${response.statusCode}: ${response.body}");
        return 'api_error';
      }
    } catch (e) {
      print("❌ Razorpay check failed: $e");
      return 'exception';
    }
  }
}

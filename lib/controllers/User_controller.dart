import 'package:admin/models/User.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class UserController extends GetxController {
  RxBool isLoading = false.obs;
  RxList<User> users = <User>[].obs;
  RxList<User> filteredUsers = <User>[].obs;
  RxInt userCount = 0.obs;
  RxInt tvUserCount = 0.obs;
  RxInt rowsPerPage = 10.obs;
  RxInt last24HoursUsersCount = 0.obs;
  RxInt yesterdayUsersCount = 0.obs;
  RxInt last7DaysUsersCount = 0.obs;
  RxString searchQuery = ''.obs;
  RxString activeFilterLabel = 'All Users'.obs;
  // base list for the current active filter (before search)
  List<User> _activeFilterBase = [];

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final RxBool checkTermsAndCondition = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      CollectionReference usersRef =
          FirebaseFirestore.instance.collection('users');
      QuerySnapshot querySnapshot = await usersRef.get();
      userCount.value = querySnapshot.docs.length;
      List<User> fetchedUsers = [];
      for (var doc in querySnapshot.docs) {
        var userData = doc.data() as Map<String, dynamic>?;
        if (userData != null) {
          fetchedUsers.add(User.fromFirestore(doc.id, userData));
        }
      }

      // Exclude soft-deleted users from the active list
      users.value = fetchedUsers.where((u) => !u.isDeleted).toList();
      _activeFilterBase = List.from(users);
      _applySearch();
      calculateUserStats();
    } catch (e) {
      print("Error fetching users: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // REMOVED: fetchTvUserCount() method is no longer needed.

  void calculateUserStats() {
    DateTime now = DateTime.now();
    DateTime last24Hours = now.subtract(const Duration(hours: 24));
    DateTime yesterday = now.subtract(const Duration(days: 1));
    DateTime last7Days = now.subtract(const Duration(days: 7));

    last24HoursUsersCount.value = users
        .where((user) =>
            user.registrationDate != null &&
            user.registrationDate!.isAfter(last24Hours))
        .length;

    yesterdayUsersCount.value = users
        .where((user) =>
            user.registrationDate != null &&
            user.registrationDate!.isAfter(yesterday) &&
            user.registrationDate!.isBefore(now))
        .length;

    last7DaysUsersCount.value = users
        .where((user) =>
            user.registrationDate != null &&
            user.registrationDate!.isAfter(last7Days) &&
            user.registrationDate!.isBefore(now))
        .length;

    // --- FIX: Calculate TV user count from the fetched user list ---
    // This logic correctly checks if the devices map exists and contains the 'AndroidTV' key.
    tvUserCount.value = users.where((user) {
      return user.devices != null && user.devices!.containsKey('AndroidTV');
    }).length;
  }

  void _applySearch() {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      filteredUsers.value = List.from(_activeFilterBase);
    } else {
      filteredUsers.value = _activeFilterBase.where((u) {
        return (u.name?.toLowerCase().contains(q) ?? false) ||
            (u.email?.toLowerCase().contains(q) ?? false) ||
            (u.phone?.contains(q) ?? false);
      }).toList();
    }
  }

  void searchUsers(String query) {
    searchQuery.value = query;
    _applySearch();
  }

  void filterTvUsers() {
    _activeFilterBase = users
        .where((u) => u.devices != null && u.devices!.containsKey('AndroidTV'))
        .toList();
    activeFilterLabel.value = 'TV Users';
    _applySearch();
  }

  void filterLast24Hours() {
    final last24Hours = DateTime.now().subtract(const Duration(hours: 24));
    _activeFilterBase = users
        .where((u) =>
            u.registrationDate != null &&
            u.registrationDate!.isAfter(last24Hours))
        .toList();
    activeFilterLabel.value = 'Last 24 Hours';
    _applySearch();
  }

  void filterActiveUsers() {
    _activeFilterBase = users.where((u) => u.active == true).toList();
    activeFilterLabel.value = 'Active';
    _applySearch();
  }

  void filterInactiveUsers() {
    _activeFilterBase = users.where((u) => u.active != true).toList();
    activeFilterLabel.value = 'Inactive';
    _applySearch();
  }

  void clearFilter() {
    _activeFilterBase = List.from(users);
    activeFilterLabel.value = 'All Users';
    _applySearch();
  }

  void clearInputFields() {
    emailController.clear();
    nameController.clear();
    phoneController.clear();
    checkTermsAndCondition.value = false;
  }

  List<User> getUsersInRegistrationDateRange(
      DateTime startDate, DateTime endDate) {
    return users.where((user) {
      if (user.isDeleted) return false;
      if (user.registrationDate == null) return false;

      return user.registrationDate!
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          user.registrationDate!
              .isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  List<User> getUsersInSubscriptionDateRange(
      DateTime startDate, DateTime endDate) {
    List<User> filteredUsers = users.where((user) {
      if (user.isDeleted) {
        return false;
      }
      if (user.active != true) {
        return false;
      }
      if (user.subscriptionStartDate == null) {
        return false;
      }

      bool isInRange = user.subscriptionStartDate!
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          user.subscriptionStartDate!
              .isBefore(endDate.add(const Duration(days: 1)));

      return isInRange;
    }).toList();

    return filteredUsers;
  }

  int getUsersCountForTimeRange(DateTime startDate, DateTime? endDate) {
    endDate ??= DateTime.now();
    return users.where((user) {
      if (user.isDeleted) return false;
      DateTime? regDate = user.registrationDate;
      if (regDate == null) return false;

      return regDate.isAfter(startDate.subtract(Duration(days: 1))) &&
          regDate.isBefore(endDate!.add(Duration(days: 1)));
    }).length;
  }

  List<User> getUsersWithValidDates() {
    return users
        .where((user) => !user.isDeleted && user.registrationDate != null)
        .toList();
  }

  Future<void> updateUser(String userId, User updatedUser) async {
    try {
      CollectionReference usersRef =
          FirebaseFirestore.instance.collection('users');
      await usersRef.doc(userId).update(updatedUser.toMap());
      fetchUsers();
    } catch (e) {
      print("Error updating user: $e");
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      CollectionReference usersRef =
          FirebaseFirestore.instance.collection('users');
      await usersRef.doc(userId).update({'isDeleted': true});
      fetchUsers();
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  Future<void> hardDeleteUser(String userId) async {
    try {
      CollectionReference usersRef =
          FirebaseFirestore.instance.collection('users');
      await usersRef.doc(userId).delete();
      fetchUsers();
    } catch (e) {
      print("Error hard deleting user: $e");
    }
  }

  Future<void> exportToExcel() async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Users'];

    sheet.appendRow([
      'Sr No',
      'Name',
      'Email',
      'Phone',
      'Registration Date',
      'Subscription Active',
      'Subscription Type',
      'Sub Start Date',
      'Sub Expiry Date',
      'Days Until Expiry',
      'TV User',
      'Payment Status',
    ].map((h) => TextCellValue(h)).toList());

    int srNo = 1;
    for (var user in filteredUsers) {
      final daysLeft = user.subscriptionExpiryDate != null
          ? user.subscriptionExpiryDate!.difference(DateTime.now()).inDays
          : 0;
      final isTv =
          (user.devices != null && user.devices!.containsKey('AndroidTV'))
              ? 'Yes'
              : 'No';
      final subStatus = (user.active == true) ? 'Active' : 'Inactive';
      String subType = user.subscriptionType ?? 'N/A';
      if (subType == 'basic_plan_id') subType = 'Basic';

      sheet.appendRow([
        TextCellValue(srNo.toString()),
        TextCellValue(user.name ?? 'N/A'),
        TextCellValue(user.email ?? 'N/A'),
        TextCellValue(user.phone ?? 'N/A'),
        TextCellValue(user.registrationDate != null
            ? dateFormat.format(user.registrationDate!)
            : 'N/A'),
        TextCellValue(subStatus),
        TextCellValue(subType),
        TextCellValue(user.subscriptionStartDate != null
            ? dateFormat.format(user.subscriptionStartDate!)
            : 'N/A'),
        TextCellValue(user.subscriptionExpiryDate != null
            ? dateFormat.format(user.subscriptionExpiryDate!)
            : 'N/A'),
        TextCellValue(daysLeft > 0 ? '$daysLeft days' : 'Expired'),
        TextCellValue(isTv),
        TextCellValue(user.purchaseToken?.isNotEmpty == true ? 'Paid' : 'N/A'),
      ]);
      srNo++;
    }

    final fileName =
        'Users_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final fileBytes = excel.save();
    if (fileBytes == null) return;

    if (kIsWeb) {
      excel.save(fileName: fileName);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      File('${directory.path}/$fileName')
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
    }
  }

  Future<void> exportToPdf(List<User> filteredUsers) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: pw.EdgeInsets.all(32),
        ),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Videos Alarm - User Report",
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              "Generated on: ${dateFormat.format(DateTime.now())}",
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.Divider(),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              "Page ${context.pageNumber} of ${context.pagesCount}",
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            )
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: ['Name', 'Phone', 'Registration Date'],
            data: filteredUsers.map((user) {
              return [
                user.name ?? 'N/A',
                user.phone ?? 'N/A',
                user.registrationDate != null
                    ? dateFormat.format(user.registrationDate!)
                    : 'N/A'
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            oddRowDecoration: pw.BoxDecoration(color: PdfColors.grey100),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
            },
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}
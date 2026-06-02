import 'package:admin/models/User.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  RxInt tvUserCount = 0.obs; // Holds the count of TV users
  RxInt rowsPerPage = 10.obs;
  RxInt last24HoursUsersCount = 0.obs;
  RxInt yesterdayUsersCount = 0.obs;
  RxInt last7DaysUsersCount = 0.obs;

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

      users.value = fetchedUsers;
      filteredUsers.value = users;
      // This function now also calculates the TV user count
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

  // This filtering method is already correct and uses the same logic as the count.
  void filterTvUsers() {
    filteredUsers.value = users.where((user) {
      return user.devices != null && user.devices!.containsKey('AndroidTV');
    }).toList();
  }

  void filterLast24Hours() {
    DateTime last24Hours = DateTime.now().subtract(const Duration(hours: 24));
    filteredUsers.value = users
        .where((user) =>
            user.registrationDate != null &&
            user.registrationDate!.isAfter(last24Hours))
        .toList();
  }

  void clearFilter() {
    filteredUsers.value = users;
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
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Users'];

    List<TextCellValue> headers = [
      TextCellValue('Name'),
      TextCellValue('Email'),
      TextCellValue('Phone'),
      TextCellValue('Registration Date')
    ];
    sheetObject.appendRow(headers);

    for (var user in filteredUsers) {
      sheetObject.appendRow([
        TextCellValue(user.name ?? 'N/A'),
        TextCellValue(user.email ?? 'N/A'),
        TextCellValue(user.phone ?? 'N/A'),
        TextCellValue(user.registrationDate?.toIso8601String() ?? 'N/A')
      ]);
    }

    var fileBytes = excel.save();
    var directory = await getApplicationDocumentsDirectory();
    File(
      '${directory.path}/users.xlsx',
    )
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes!);
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
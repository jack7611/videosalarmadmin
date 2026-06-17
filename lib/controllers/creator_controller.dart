import 'package:admin/models/Creator.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorController extends GetxController {
  var creators = <Creator>[].obs;
  var filteredCreators = <Creator>[].obs;
  var isLoading = true.obs;
  var error = ''.obs;
  RxInt rowsPerPage = 10.obs;
  var creatorEarnings = <String, double>{}.obs;
  var ratePerWatchHour = 50.0.obs;
  // Total amount released (paid out) per creator
  var creatorReleasedAmounts = <String, double>{}.obs;
  // Increments on every successful release so Obx widgets rebuild
  var releaseVersion = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCreators();
  }

  Future<void> fetchCreatorEarnings() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('settings').doc('earnings').get(),
        FirebaseFirestore.instance.collection('newvideos').get(),
      ]);

      final rateDoc = results[0] as DocumentSnapshot;
      final videosSnap = results[1] as QuerySnapshot;

      final rateRaw =
          (rateDoc.data() as Map<String, dynamic>?)?['ratePerWatchHour'];
      ratePerWatchHour.value =
          rateRaw != null ? (rateRaw as num).toDouble() : 50.0;

      final Map<String, int> watchSecondsMap = {};
      for (final doc in videosSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final cId = data['creatorId'] as String?;
        final ws = (data['watchSeconds'] as num?)?.toInt() ?? 0;
        if (cId != null) {
          watchSecondsMap[cId] = (watchSecondsMap[cId] ?? 0) + ws;
        }
      }

      final Map<String, double> newEarnings = {};
      for (final entry in watchSecondsMap.entries) {
        newEarnings[entry.key] =
            (entry.value / 3600.0) * ratePerWatchHour.value;
      }
      creatorEarnings.value = newEarnings;
    } catch (e) {
      print('Error fetching creator earnings: $e');
    }
  }

  /// Loads total released amounts per creator from creator_payments collection.
  Future<void> fetchReleasedAmounts() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('creator_payments')
          .get();
      final Map<String, double> released = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final cId = data['creatorId'] as String?;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        if (cId != null) {
          released[cId] = (released[cId] ?? 0.0) + amount;
        }
      }
      creatorReleasedAmounts.value = released;
    } catch (e) {
      print('Error fetching released amounts: $e');
    }
  }

  /// Available wallet = total earned - total released (minimum 0).
  double availableWallet(String creatorId) {
    final earned = creatorEarnings[creatorId] ?? 0.0;
    final released = creatorReleasedAmounts[creatorId] ?? 0.0;
    return (earned - released).clamp(0.0, double.infinity);
  }

  /// Records a payment release. Returns null on success, error string on failure.
  Future<String?> releasePayment({
    required String creatorId,
    required String creatorName,
    required double amount,
    String? note,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('creator_payments').add({
        'creatorId': creatorId,
        'creatorName': creatorName,
        'amount': amount,
        'note': note ?? '',
        'releasedAt': FieldValue.serverTimestamp(),
      });
      // Update local map immediately and bump version so table rebuilds
      final current = creatorReleasedAmounts[creatorId] ?? 0.0;
      creatorReleasedAmounts[creatorId] = current + amount;
      releaseVersion.value++;
      return null; // success
    } catch (e) {
      print('Error releasing payment: $e');
      return e.toString(); // return actual error so UI can display it
    }
  }

  // Fetch all creators from Firestore
  Future<void> fetchCreators() async {
    try {
      isLoading.value = true;
      final snapshot = await FirebaseFirestore.instance.collection('creators').get();
      var fetchedCreators = snapshot.docs.map((doc) {
        return Creator.fromFirestore(doc.id, doc.data());
      }).toList();

      creators.value = fetchedCreators;
      filteredCreators.value = fetchedCreators;
      error.value = '';
      fetchCreatorEarnings();
      fetchReleasedAmounts();
    } catch (e) {
      print("Error fetching creators: $e");
      error.value = "Failed to fetch creators: $e";
    } finally {
      isLoading.value = false;
    }
  }

  // Update creator details
  Future<void> updateCreator({
    required String creatorId,
    required Map<String, dynamic> updatedFields,
  }) async {
    try {
      isLoading.value = true;
      await FirebaseFirestore.instance.collection('creators').doc(creatorId).update(updatedFields);

      // Update the local list
      int index = creators.indexWhere((creator) => creator.id == creatorId);
      if (index != -1) {
        var updatedCreator = creators[index];
        if (updatedFields.containsKey('name')) {
          updatedCreator = updatedCreator.copyWith(name: updatedFields['name']);
        }
        if (updatedFields.containsKey('companyName')) {
          updatedCreator = updatedCreator.copyWith(companyName: updatedFields['companyName']);
        }
        if (updatedFields.containsKey('phoneNo')) {
          updatedCreator = updatedCreator.copyWith(phoneNo: updatedFields['phoneNo']);
        }
        if (updatedFields.containsKey('email')) {
          updatedCreator = updatedCreator.copyWith(email: updatedFields['email']);
        }
        if (updatedFields.containsKey('password')) {
          updatedCreator = updatedCreator.copyWith(password: updatedFields['password']);
        }
        if (updatedFields.containsKey('active')) {
          updatedCreator = updatedCreator.copyWith(active: updatedFields['active']);
        }
        creators[index] = updatedCreator;
      }

      fetchCreators(); // Refresh the list
      error.value = '';
    } catch (e) {
      print("Error updating creator: $e");
      error.value = "Failed to update creator: $e";
    } finally {
      isLoading.value = false;
    }
  }

  // Create new creator
  Future<void> createCreator({
    required String name,
    String? companyName,
    required String phoneNo,
    required String email,
    required String password,
    required bool active,
  }) async {
    try {
      isLoading.value = true;
      var newDocRef = await FirebaseFirestore.instance.collection('creators').add({
        'name': name,
        'companyName': companyName ?? '',
        'phoneNo': phoneNo,
        'email': email,
        'password': password,
        'active': active,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add new creator to local list
      var newCreator = Creator(
        id: newDocRef.id,
        name: name,
        companyName: companyName,
        phoneNo: phoneNo,
        email: email,
        password: password,
        active: active,
      );
      creators.add(newCreator);
      filteredCreators.value = creators;

      fetchCreators(); // Refresh the list
      error.value = '';
    } catch (e) {
      print("Error creating creator: $e");
      error.value = "Failed to create creator: $e";
    } finally {
      isLoading.value = false;
    }
  }

  // Delete creator
  Future<void> deleteCreator(String creatorId) async {
    try {
      await FirebaseFirestore.instance.collection('creators').doc(creatorId).delete();
      // Auto-refresh after deletion
      await fetchCreators();
      error.value = '';
    } catch (e) {
      print("Error deleting creator: $e");
      error.value = "Failed to delete creator: $e";
    }
  }

  // Clear filter (show all creators)
  void clearFilter() {
    filteredCreators.value = creators;
  }

  // Handle errors
  void _handleError(String message, Object error) {
    this.error.value = "$message: $error";
    print("$message: $error");
  }
}


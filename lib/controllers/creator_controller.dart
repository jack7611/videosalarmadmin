import 'package:admin/models/Creator.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreatorController extends GetxController {
  var creators = <Creator>[].obs;
  var filteredCreators = <Creator>[].obs;
  var isLoading = true.obs;
  var error = ''.obs;
  RxInt rowsPerPage = 10.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCreators();
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


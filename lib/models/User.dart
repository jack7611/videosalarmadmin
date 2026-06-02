import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  String? name;
  String? email;
  String? phone;
  bool? checkTermsAndCondition;
  DateTime? createdAt;
  DateTime? releaseDate; // Alternative date field
  bool? active;
  String? purchaseToken;
  DateTime? subscriptionStartDate;
  DateTime? subscriptionExpiryDate;
  String? subscriptionType;
  final bool isDeleted;
  final Map<String, dynamic>? devices; // <-- ADDED: To store user devices

  User({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.checkTermsAndCondition,
    this.createdAt,
    this.releaseDate,
    this.active,
    this.purchaseToken,
    this.subscriptionStartDate,
    this.subscriptionExpiryDate,
    this.subscriptionType,
    this.isDeleted = false,
    this.devices, // <-- ADDED: In constructor
  });

  // Getter for registration date - prioritizes createdAt, then releaseDate
  DateTime? get registrationDate {
    if (createdAt != null) {
      return createdAt;
    } else if (releaseDate != null) {
      return releaseDate;
    }
    return null;
  }

  // Create User from Firestore document
  factory User.fromFirestore(String id, Map<String, dynamic> data) {
    return User(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      checkTermsAndCondition: data['checkTermsAndCondition'] as bool? ?? false,
      createdAt: _parseTimestamp(data['createdAt']),
      releaseDate: _parseTimestamp(data['releaseDate']),
      active: data['Active'] as bool? ?? false,
      purchaseToken: data['PurchaseToken'] as String? ?? '',
      subscriptionStartDate: _parseTimestamp(data['SubscriptionStartDate']),
      subscriptionExpiryDate: _parseTimestamp(data['SubscriptionExpiryDate']),
      subscriptionType: data['SubscriptionType'] as String? ?? 'basic_plan_id',
      isDeleted: data['isDeleted'] as bool? ?? false,
      // <-- ADDED: Safely cast the devices map
      devices: data['devices'] is Map<String, dynamic>
          ? data['devices'] as Map<String, dynamic>
          : null,
    );
  }

  // Helper method to parse Firestore timestamps
  static DateTime? _parseTimestamp(dynamic timestampData) {
    if (timestampData == null) return null;
    try {
      if (timestampData is Timestamp) {
        return timestampData.toDate();
      } else if (timestampData is String) {
        return DateTime.tryParse(timestampData);
      } else if (timestampData is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestampData);
      }
    } catch (e) {
      print("Error parsing timestamp: $e");
    }
    return null;
  }

  // Convert User to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'checkTermsAndCondition': checkTermsAndCondition,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'releaseDate': releaseDate != null ? Timestamp.fromDate(releaseDate!) : null,
      'active': active,
      'purchaseToken': purchaseToken,
      'subscriptionStartDate': subscriptionStartDate != null
          ? Timestamp.fromDate(subscriptionStartDate!)
          : null,
      'subscriptionExpiryDate': subscriptionExpiryDate != null
          ? Timestamp.fromDate(subscriptionExpiryDate!)
          : null,
      'subscriptionType': subscriptionType,
      'isDeleted': isDeleted,
      'devices': devices, // <-- ADDED: To map
    };
  }

  // Create a copy of the user with updated fields
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    bool? checkTermsAndCondition,
    DateTime? createdAt,
    DateTime? releaseDate,
    bool? active,
    String? purchaseToken,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionExpiryDate,
    String? subscriptionType,
    bool? isDeleted,
    Map<String, dynamic>? devices, // <-- ADDED: To copyWith
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      checkTermsAndCondition: checkTermsAndCondition ?? this.checkTermsAndCondition,
      createdAt: createdAt ?? this.createdAt,
      releaseDate: releaseDate ?? this.releaseDate,
      active: active ?? this.active,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      isDeleted: isDeleted ?? this.isDeleted,
      devices: devices ?? this.devices, // <-- ADDED
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, registrationDate: $registrationDate, isDeleted: $isDeleted, devices: $devices, subscriptionStartDate: $subscriptionStartDate)';
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class Creator {
  final String id;
  String? name; // Creator name
  String? companyName;
  String? phoneNo;
  String? email;
  String? password;
  bool? active; // Active/Inactive status
  DateTime? createdAt;

  Creator({
    required this.id,
    this.name,
    this.companyName,
    this.phoneNo,
    this.email,
    this.password,
    this.active,
    this.createdAt,
  });

  // Create Creator from Firestore document
  factory Creator.fromFirestore(String id, Map<String, dynamic> data) {
    return Creator(
      id: id,
      name: data['name'] as String? ?? '',
      companyName: data['companyName'] as String? ?? '',
      phoneNo: data['phoneNo'] as String? ?? '',
      email: data['email'] as String? ?? '',
      password: data['password'] as String? ?? '',
      active: data['active'] as bool? ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
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

  // Convert Creator to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'companyName': companyName,
      'phoneNo': phoneNo,
      'email': email,
      'password': password,
      'active': active ?? true,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  // Create a copy of the creator with updated fields
  Creator copyWith({
    String? id,
    String? name,
    String? companyName,
    String? phoneNo,
    String? email,
    String? password,
    bool? active,
    DateTime? createdAt,
  }) {
    return Creator(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      phoneNo: phoneNo ?? this.phoneNo,
      email: email ?? this.email,
      password: password ?? this.email,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Creator(id: $id, name: $name, companyName: $companyName, email: $email, password: $password active: $active)';
  }
}

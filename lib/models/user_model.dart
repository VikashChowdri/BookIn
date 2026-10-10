import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String publicName;
  final String profilePictureUrl;
  final DateTime createdAt;
  final String? phone;
  final String? bio;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.publicName,
    required this.profilePictureUrl,
    required this.createdAt,
    this.phone,
    this.bio,
  });

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? publicName,
    String? profilePictureUrl,
    DateTime? createdAt,
    String? phone,
    String? bio,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      publicName: publicName ?? this.publicName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'publicName': publicName,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      if (phone != null) 'phone': phone,
      if (bio != null) 'bio': bio,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      id: documentId,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      publicName: map['publicName'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      phone: map['phone'],
      bio: map['bio'],
    );
  }
}

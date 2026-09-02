import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    super.photoUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromFirebaseUser(firebase.User user) {
    return UserModel(
      uid: user.uid,
      name: user.displayName ?? 'Tailor',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      createdAt: DateTime.now(), // Fallback, managed primarily on Firestore side
      updatedAt: DateTime.now(), // Fallback, managed primarily on Firestore side
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class UserEntity {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final bool isActive;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.isActive = false,
    this.role = 'user',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOwner => role == 'owner';
}

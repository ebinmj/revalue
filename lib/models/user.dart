class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.profileImage,
  });

  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final String? profileImage;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      profileImage: json['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    if (profileImage != null) 'profileImage': profileImage,
  };
}

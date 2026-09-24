class UserModel {
  final String id;
  final String email;
  final String password;
  final String? name;
  final bool isTeacher;
  final String? role;

  const UserModel({
    required this.id,
    required this.email,
    required this.password,
    this.name,
    this.isTeacher = false,
    this.role,
  });

  bool get isAdmin {
    if (role != null && role!.toLowerCase() == 'admin') return true;
    if (id.toLowerCase() == 'admin') return true;
    return !isTeacher;
  }

  /// Factory constructor to map Firestore document data to [UserModel].
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawIsTeacher = data['isTeacher'];
    final rawRole = data['role'] ?? data['rol'];

    bool isTeacher = false;
    if (rawIsTeacher is bool) {
      isTeacher = rawIsTeacher;
    } else if (rawRole is String && rawRole.toLowerCase() == 'teacher') {
      isTeacher = true;
    }

    return UserModel(
      id: id,
      email: data['email'] as String? ?? '',
      password: data['password'] as String? ?? '',
      name: data['name'] as String? ?? data['nombre'] as String?,
      isTeacher: isTeacher,
      role: rawRole as String?,
    );
  }

  /// Factory constructor from JSON map for SharedPreferences local storage.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      name: json['name'] as String?,
      isTeacher: json['isTeacher'] as bool? ?? false,
      role: json['role'] as String?,
    );
  }

  /// Serialize to JSON map for SharedPreferences local storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'name': name,
      'isTeacher': isTeacher,
      'role': role,
    };
  }
}

enum UserRole {
  admin,
  section_owner,
  channel_owner,
  student;

  String get value => name;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => UserRole.student,
    );
  }
}

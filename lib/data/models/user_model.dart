import '../../core/enums/user_role.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? collegeTrust;
  final String? sectionId;
  final List<String> joinedSections;
  final List<String> defaultChannels;
  final List<String> joinedChannels;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.collegeTrust,
    this.sectionId,
    this.joinedSections = const [],
    this.defaultChannels = const [],
    this.joinedChannels = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: UserRole.fromString(map['role'] ?? 'student'),
      collegeTrust: map['college_trust'] ?? map['collegeTrust'],
      sectionId: map['section_id'] ?? map['sectionId'],
      joinedSections: List<String>.from(map['joined_sections'] ?? []),
      defaultChannels: List<String>.from(map['default_channels'] ?? []),
      joinedChannels: List<String>.from(map['joined_channels'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.value,
      'college_trust': collegeTrust,
      'section_id': sectionId,
      'joined_sections': joinedSections,
      'default_channels': defaultChannels,
      'joined_channels': joinedChannels,
    };
  }
}

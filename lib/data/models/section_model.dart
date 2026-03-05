class SectionModel {
  final String id;
  final String name;
  final String collegeTrust;
  final String? ownerName;
  final String? ownerEmail;
  final int studentCount;

  SectionModel({
    required this.id,
    required this.name,
    required this.collegeTrust,
    this.ownerName,
    this.ownerEmail,
    this.studentCount = 0,
  });

  factory SectionModel.fromMap(Map<String, dynamic> map, String docId) {
    return SectionModel(
      id: docId,
      name: map['name'] ?? '',
      collegeTrust: map['college_trust'] ?? '',
      ownerName: map['owner_name'],
      ownerEmail: map['owner_email'],
      studentCount: map['student_count'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'college_trust': collegeTrust,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
      'student_count': studentCount,
    };
  }
}

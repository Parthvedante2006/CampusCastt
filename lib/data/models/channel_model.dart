class ChannelModel {
  final String id;
  final String name;
  final String sectionId;
  final String sectionName;
  final String? ownerName;
  final String? ownerEmail;
  final bool isDefault;
  final bool isLive;
  final String? activeBroadcastId;

  ChannelModel({
    required this.id,
    required this.name,
    required this.sectionId,
    required this.sectionName,
    this.ownerName,
    this.ownerEmail,
    this.isDefault = false,
    this.isLive = false,
    this.activeBroadcastId,
  });

  factory ChannelModel.fromMap(Map<String, dynamic> map, String docId) {
    return ChannelModel(
      id: docId,
      name: map['name'] ?? '',
      sectionId: map['section_id'] ?? '',
      sectionName: map['section_name'] ?? '',
      ownerName: map['owner_name'],
      ownerEmail: map['owner_email'],
      isDefault: map['is_default'] ?? false,
      isLive: map['is_live'] ?? false,
      activeBroadcastId: map['active_broadcast_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'section_id': sectionId,
      'section_name': sectionName,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
      'is_default': isDefault,
      'is_live': isLive,
      'active_broadcast_id': activeBroadcastId,
    };
  }
}

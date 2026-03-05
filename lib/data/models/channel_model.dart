class ChannelModel {
  final String channelId;
  final String name;
  final bool isLive;
  final String? activeBroadcastId;

  const ChannelModel({
    required this.channelId,
    required this.name,
    required this.isLive,
    this.activeBroadcastId,
  });

  factory ChannelModel.fromMap(String id, Map<String, dynamic> map) {
    return ChannelModel(
      channelId:         id,
      name:              map['name']              as String? ?? '',
      isLive:            map['isLive']            as bool?   ?? false,
      activeBroadcastId: map['activeBroadcastId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'name':              name,
    'isLive':            isLive,
    'activeBroadcastId': activeBroadcastId,
  };

  ChannelModel copyWith({
    String?  channelId,
    String?  name,
    bool?    isLive,
    String?  activeBroadcastId,
  }) {
    return ChannelModel(
      channelId:         channelId         ?? this.channelId,
      name:              name              ?? this.name,
      isLive:            isLive            ?? this.isLive,
      activeBroadcastId: activeBroadcastId ?? this.activeBroadcastId,
    );
  }

  @override
  String toString() =>
      'ChannelModel(id: $channelId, name: $name, isLive: $isLive, broadcastId: $activeBroadcastId)';
}

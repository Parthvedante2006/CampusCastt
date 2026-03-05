class BroadcastModel {
  final String broadcastId;
  final String channelId;
  final String streamUrl;
  final String title;
  final String description;
  final int listeners;
  final String status; // "live" | "ended" | "idle"

  const BroadcastModel({
    required this.broadcastId,
    required this.channelId,
    required this.streamUrl,
    required this.title,
    required this.description,
    required this.listeners,
    required this.status,
  });

  factory BroadcastModel.fromMap(Map<String, dynamic> map) {
    return BroadcastModel(
      broadcastId: map['broadcastId'] as String? ?? '',
      channelId:   map['channelId']   as String? ?? '',
      streamUrl:   map['streamUrl']   as String? ?? '',
      title:       map['title']       as String? ?? '',
      description: map['description'] as String? ?? '',
      listeners:   (map['listeners']  as num?)?.toInt() ?? 0,
      status:      map['status']      as String? ?? 'idle',
    );
  }

  Map<String, dynamic> toMap() => {
    'broadcastId': broadcastId,
    'channelId':   channelId,
    'streamUrl':   streamUrl,
    'title':       title,
    'description': description,
    'listeners':   listeners,
    'status':      status,
  };

  BroadcastModel copyWith({
    String?  broadcastId,
    String?  channelId,
    String?  streamUrl,
    String?  title,
    String?  description,
    int?     listeners,
    String?  status,
  }) {
    return BroadcastModel(
      broadcastId: broadcastId ?? this.broadcastId,
      channelId:   channelId   ?? this.channelId,
      streamUrl:   streamUrl   ?? this.streamUrl,
      title:       title       ?? this.title,
      description: description ?? this.description,
      listeners:   listeners   ?? this.listeners,
      status:      status      ?? this.status,
    );
  }

  @override
  String toString() =>
      'BroadcastModel(id: $broadcastId, channel: $channelId, status: $status, listeners: $listeners)';
}

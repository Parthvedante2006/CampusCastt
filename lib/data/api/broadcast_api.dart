import 'package:campuscast/data/api/api_client.dart';

class BroadcastApi {
  final _dio = ApiClient.instance;

  /// Calls GET /broadcast/{broadcastId}/url
  /// Returns the HLS stream URL string.
  /// Throws if the broadcast is not found or server is unreachable.
  Future<String> getStreamUrl(String broadcastId) async {
    final response = await _dio.get('/broadcast/$broadcastId/url');
    final data = response.data as Map<String, dynamic>;
    return data['stream_url'] as String;
  }

  /// Calls GET /broadcast/active
  /// Returns a list of currently active broadcast IDs on the server.
  Future<List<String>> getActiveBroadcasts() async {
    final response = await _dio.get('/broadcast/active');
    final data = response.data as Map<String, dynamic>;
    return List<String>.from(data['active_broadcasts'] ?? []);
  }
}

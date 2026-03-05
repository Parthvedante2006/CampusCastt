class AppConfig {
  /// Base URL of the CampusCastt backend server.
  /// Update this every time ngrok restarts (or use a fixed domain in production).
  static const String serverUrl = "http://10.25.28.6:8000";
  // ↑ 10.0.2.2 maps to localhost when running on Android emulator.
  // For a real device on the same WiFi, use your PC's local IP, e.g. "http://192.168.x.x:8000"
  // For production, replace with your ngrok URL: "https://xxxx.ngrok-free.app"

  /// HLS segment path prefix (served as static files by FastAPI)
  static const String streamBasePath = "/stream";
}

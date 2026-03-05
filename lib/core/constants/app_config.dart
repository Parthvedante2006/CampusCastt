class AppConfig {
  /// Base URL of the CampusCastt backend server.
  /// Update this every time ngrok restarts (or use a fixed domain in production).
  static const String serverUrl = "https://currently-unforewarned-lucie.ngrok-free.dev";
  // ↑ ngrok URL - Active now!
  // Local IP fallback: "http://10.25.28.6:8000"
  // Android emulator: "http://10.0.2.2:8000"

  /// HLS segment path prefix (served as static files by FastAPI)
  static const String streamBasePath = "/stream";
}

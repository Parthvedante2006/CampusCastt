import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campuscast/core/services/notification_service.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase — google-services.json handles the config on Android
  try {
    await Firebase.initializeApp();
    debugPrint('[main] ✅ Firebase initialized');
  } catch (e) {
    debugPrint('[main] ⚠️ Firebase init failed: $e');
    // App will still launch — Firestore calls will show errors gracefully
  }

  // Initialize FCM notifications
  try {
    await NotificationService.instance.initialize();
    debugPrint('[main] ✅ FCM notifications initialized');
  } catch (e) {
    debugPrint('[main] ⚠️ FCM init failed: $e');
  }

  // ProviderScope MUST wrap the app here, NOT inside app.dart build()
  runApp(
    const ProviderScope(
      child: CampusCasttApp(),
    ),
  );
}

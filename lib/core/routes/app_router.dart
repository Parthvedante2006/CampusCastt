import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:campuscast/presentation/student/home_screen.dart';
import 'package:campuscast/presentation/student/live_player_screen.dart';
import 'package:campuscast/presentation/channel_owner/go_live_screen.dart';
import 'package:campuscast/presentation/auth/screens/login_screen.dart';
import 'package:campuscast/presentation/auth/screens/register_screen.dart';
import 'package:campuscast/presentation/admin/screens/admin_dashboard_screen.dart';
import 'package:campuscast/presentation/section_owner/screens/section_dashboard_screen.dart';
import 'package:campuscast/presentation/channel_owner/screens/channel_dashboard_screen.dart';
import 'package:campuscast/presentation/channel_owner/screens/broadcast_screen.dart';
import 'package:campuscast/presentation/channel_owner/screens/schedule_announcement_screen.dart';
import 'package:campuscast/presentation/channel_owner/screens/schedule_screen.dart';
import 'package:campuscast/presentation/student/screens/student_home_screen.dart';
import 'package:campuscast/presentation/student/screens/channel_detail_screen.dart';
import 'package:campuscast/presentation/student/screens/event_detail_screen.dart';
import 'package:campuscast/presentation/student/screens/announcement_replay_player_screen.dart';

// ── Global navigator key for notification navigation ───────────
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// ── Route path constants ───────────────────────────────────────
class AppRoutes {
  // Auth
  static const login          = '/login';
  static const register       = '/register';

  // Dashboards (role-based)
  static const studentHome       = '/student/home';
  static const adminDashboard    = '/admin/dashboard';
  static const sectionDashboard  = '/section/dashboard';
  static const channelDashboard  = '/channel/dashboard';

  // Student routes
  static const channelDetail      = '/student/channel/:channelId';
  static const studentEventDetail = '/student/event/:eventId';

  // Channel owner routes
  static const broadcast              = '/channel/broadcast';
  static const scheduleAnnouncement   = '/channel/schedule-announcement';
  static const channelEvents          = '/channel/events';

  // Broadcast (friend's routes)
  static const home        = '/';
  static const goLive      = '/go-live';
  static const livePlayer  = '/live-player';
  static const replayPlayer = '/replay-player';
}

// ── Router definition ──────────────────────────────────────────
// NOTE: initialLocation and redirect are set dynamically in app.dart
GoRouter createAppRouter({required String initialLocation}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      // ── Auth routes ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Dashboard routes ───────────────────────────────────────
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.channelDetail,
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          return ChannelDetailScreen(channelId: channelId);
        },
      ),
      GoRoute(
        path: AppRoutes.studentEventDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return StudentEventDetailScreen(event: extra['event']);
        },
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.sectionDashboard,
        builder: (context, state) => const SectionOwnerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.channelDashboard,
        builder: (context, state) => const ChannelOwnerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.broadcast,
        builder: (context, state) => const BroadcastScreen(),
      ),
      GoRoute(
        path: AppRoutes.channelEvents,
        builder: (context, state) => const ChannelOwnerEventsScreen(),
      ),
      GoRoute(
        path: AppRoutes.scheduleAnnouncement,
        builder: (context, state) {
          final extra = Map<String, dynamic>.from(
            (state.extra as Map?) ?? const {},
          );
          return ScheduleAnnouncementScreen(
            channelId: extra['channelId']?.toString() ?? '',
            channelName: extra['channelName']?.toString() ?? '',
          );
        },
      ),

      // ── Broadcast routes (friend's) ────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.goLive,
        builder: (context, state) {
          final extra = Map<String, dynamic>.from(
            (state.extra as Map?) ?? const {},
          );
          return GoLiveScreen(
            channelId:   extra['channelId']?.toString() ?? '',
            channelName: extra['channelName']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.livePlayer,
        builder: (context, state) {
          final extra = Map<String, dynamic>.from(
            (state.extra as Map?) ?? const {},
          );
          return LivePlayerScreen(
            broadcastId:  extra['broadcastId']?.toString() ?? '',
            channelName:  extra['channelName']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.replayPlayer,
        builder: (context, state) {
          final extra = Map<String, dynamic>.from(
            (state.extra as Map?) ?? const {},
          );
          return AnnouncementReplayPlayerScreen(
            audioUrl: extra['audioUrl']?.toString() ?? '',
            title: extra['title']?.toString() ?? 'Announcement Replay',
            channelName: extra['channelName']?.toString() ?? 'Channel',
          );
        },
      ),
    ],
  );
}

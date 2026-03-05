import 'package:go_router/go_router.dart';
import 'package:campuscast/presentation/student/home_screen.dart';
import 'package:campuscast/presentation/student/live_player_screen.dart';
import 'package:campuscast/presentation/channel_owner/go_live_screen.dart';
import 'package:campuscast/presentation/auth/screens/login_screen.dart';
import 'package:campuscast/presentation/auth/screens/register_screen.dart';
import 'package:campuscast/presentation/admin/screens/admin_dashboard_screen.dart';
import 'package:campuscast/presentation/section_owner/screens/section_dashboard_screen.dart';
import 'package:campuscast/presentation/channel_owner/screens/channel_dashboard_screen.dart';
import 'package:campuscast/presentation/student/screens/student_home_screen.dart';

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

  // Broadcast (friend's routes)
  static const home        = '/';
  static const goLive      = '/go-live';
  static const livePlayer  = '/live-player';
}

// ── Router definition ──────────────────────────────────────────
// NOTE: initialLocation and redirect are set dynamically in app.dart
GoRouter createAppRouter({required String initialLocation}) {
  return GoRouter(
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

      // ── Broadcast routes (friend's) ────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.goLive,
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return GoLiveScreen(
            channelId:   extra['channelId']!,
            channelName: extra['channelName']!,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.livePlayer,
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return LivePlayerScreen(
            broadcastId:  extra['broadcastId']!,
            channelName:  extra['channelName']!,
          );
        },
      ),
    ],
  );
}

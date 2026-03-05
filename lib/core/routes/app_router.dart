import 'package:go_router/go_router.dart';
import 'package:campuscast/presentation/student/home_screen.dart';
import 'package:campuscast/presentation/student/live_player_screen.dart';
import 'package:campuscast/presentation/channel_owner/go_live_screen.dart';

// ── Route path constants ───────────────────────────────────────
class AppRoutes {
  static const home      = '/';
  static const goLive    = '/go-live';
  static const livePlayer = '/live-player';
}

// ── Router definition ──────────────────────────────────────────
final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    // ── Home: list of all channels ─────────────────────────────
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),

    // ── GoLiveScreen: moderator broadcasts audio ───────────────
    // Usage: context.go('/go-live', extra: {'channelId': 'ch001', 'channelName': 'CSE Dept'})
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

    // ── LivePlayerScreen: student listens ──────────────────────
    // Usage: context.go('/live-player', extra: {'broadcastId': 'xxx', 'channelName': 'CSE Dept'})
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

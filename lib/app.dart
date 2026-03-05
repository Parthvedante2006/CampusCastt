import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:campuscast/core/constants/app_colors.dart';
import 'package:campuscast/core/enums/user_role.dart';
import 'package:campuscast/core/routes/app_router.dart';
import 'package:campuscast/domain/providers/auth_provider.dart';

// NOTE: ProviderScope is in main.dart — do NOT add it here
class CampusCasttApp extends ConsumerWidget {
  const CampusCasttApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const Scaffold(
          backgroundColor: AppColors.primaryBg,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.graphic_eq, size: 60, color: AppColors.white),
                SizedBox(height: 16),
                Text('CampusCast', style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                CircularProgressIndicator(color: AppColors.accentBlue),
              ],
            ),
          ),
        ),
      ),
      error: (e, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          routerConfig: createAppRouter(initialLocation: AppRoutes.login),
        ),
      ),
      data: (user) {
        if (user == null) {
          // Not logged in → show login
          return MaterialApp.router(
            title: 'CampusCast',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            routerConfig: createAppRouter(initialLocation: AppRoutes.login),
          );
        }

        // Logged in → fetch role and decide initial route
        final currentUser = ref.watch(currentUserProvider);

        return currentUser.when(
          loading: () => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            home: const Scaffold(
              backgroundColor: AppColors.primaryBg,
              body: Center(child: CircularProgressIndicator(color: AppColors.accentBlue)),
            ),
          ),
          error: (e, _) => MaterialApp.router(
            title: 'CampusCast',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            routerConfig: createAppRouter(initialLocation: AppRoutes.login),
          ),
          data: (userModel) {
            String initialRoute = AppRoutes.studentHome;

            if (userModel != null) {
              switch (userModel.role) {
                case UserRole.admin:
                  initialRoute = AppRoutes.adminDashboard;
                  break;
                case UserRole.section_owner:
                  initialRoute = AppRoutes.sectionDashboard;
                  break;
                case UserRole.channel_owner:
                  initialRoute = AppRoutes.channelDashboard;
                  break;
                case UserRole.student:
                  initialRoute = AppRoutes.studentHome;
                  break;
              }
            }

            return MaterialApp.router(
              title: 'CampusCast',
              debugShowCheckedModeBanner: false,
              theme: _buildTheme(),
              routerConfig: createAppRouter(initialLocation: initialRoute),
            );
          },
        );
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.primaryBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accentBlue,
        brightness: Brightness.dark,
        primary: AppColors.accentBlue,
        surface: AppColors.cardBg,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

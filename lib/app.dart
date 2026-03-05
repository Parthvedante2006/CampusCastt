import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:campuscast/core/routes/app_router.dart';

// NOTE: ProviderScope is in main.dart — do NOT add it here
class CampusCasttApp extends StatelessWidget {
  const CampusCasttApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ── Meta ──────────────────────────────────────────────
      title: 'CampusCastt',
      debugShowCheckedModeBanner: false,

      // ── Router ────────────────────────────────────────────
      routerConfig: appRouter,

      // ── Theme ─────────────────────────────────────────────
      theme: ThemeData(
        brightness:   Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor:  Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation:       0,
          centerTitle:     true,
        ),
      ),
    );
  }
}

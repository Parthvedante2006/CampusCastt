import 'package:flutter/material.dart';

class ReplayScreen extends StatelessWidget {
  const ReplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A1628),
      body: Center(child: Text('Replays (Coming Soon)', style: TextStyle(color: Colors.white))),
    );
  }
}

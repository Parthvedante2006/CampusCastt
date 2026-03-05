import 'dart:async';
import 'package:flutter/material.dart';

/// Counts up from 00:00 when mounted. Stops when disposed.
class BroadcastTimer extends StatefulWidget {
  const BroadcastTimer({super.key});

  @override
  State<BroadcastTimer> createState() => _BroadcastTimerState();
}

class _BroadcastTimerState extends State<BroadcastTimer> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatted,
      style: const TextStyle(
        fontSize:    22,
        fontWeight:  FontWeight.bold,
        color:       Colors.white,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

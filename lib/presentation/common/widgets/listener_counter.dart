import 'package:flutter/material.dart';

/// Shows the real-time listener count with an ear emoji.
class ListenerCounter extends StatelessWidget {
  final int count;
  const ListenerCounter({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('👂', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          '$count listening',
          style: const TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w600,
            color:      Colors.white70,
          ),
        ),
      ],
    );
  }
}

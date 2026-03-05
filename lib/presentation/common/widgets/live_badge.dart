import 'package:flutter/material.dart';

/// Red LIVE badge — optionally blinks.
class LiveBadge extends StatefulWidget {
  final bool blink;
  const LiveBadge({super.key, this.blink = true});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.3).animate(_ctrl);
    if (widget.blink) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.blink ? _opacity : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'LIVE',
          style: TextStyle(
            color:       Colors.white,
            fontWeight:  FontWeight.bold,
            fontSize:    12,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

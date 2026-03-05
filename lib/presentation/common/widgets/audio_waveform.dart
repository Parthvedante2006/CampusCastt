import 'dart:math';
import 'package:flutter/material.dart';

/// Animated bars that bounce up and down to indicate active mic input.
class AudioWaveform extends StatefulWidget {
  final int barCount;
  final Color color;
  final double maxHeight;

  const AudioWaveform({
    super.key,
    this.barCount = 5,
    this.color     = Colors.redAccent,
    this.maxHeight = 40,
  });

  @override
  State<AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<AudioWaveform>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.barCount, (i) {
      return AnimationController(
        vsync:    this,
        duration: Duration(milliseconds: 400 + _rng.nextInt(400)),
      )..repeat(reverse: true);
    });

    _animations = _controllers.map((ctrl) {
      return Tween<double>(
        begin: 0.15,
        end:   1.0,
      ).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeInOut));
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:      MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(widget.barCount, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedBuilder(
            animation: _animations[i],
            builder:   (_, __) {
              return Container(
                width:  6,
                height: widget.maxHeight * _animations[i].value,
                decoration: BoxDecoration(
                  color:        widget.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

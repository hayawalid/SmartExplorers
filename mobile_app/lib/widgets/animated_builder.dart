import 'package:flutter/material.dart';

/// A convenience AnimatedWidget that takes a builder callback.
/// Useful for inline animation transforms without creating a full subclass.
class PulseAnimatedBuilder extends AnimatedWidget {
  const PulseAnimatedBuilder({
    Key? key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(key: key, listenable: animation);

  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) => builder(context, child);
}

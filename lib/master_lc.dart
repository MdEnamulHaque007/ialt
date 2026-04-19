import 'package:flutter/material.dart';

// ─── MASTER LAYOUT COMPONENTS ─────────────────────────────
class MasterLayout extends StatelessWidget {
  final Widget child;
  final FloatingActionButton? floatingActionButton;
  const MasterLayout({
    super.key,
    required this.child,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

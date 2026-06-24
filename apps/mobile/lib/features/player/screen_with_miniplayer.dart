import 'package:Audioverse/features/content/widgets/mini_player.dart';
import 'package:flutter/material.dart';

class ScreenWithMiniplayer extends StatelessWidget {
  final Widget child;

  const ScreenWithMiniplayer ({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const SafeArea(
          top: false,
          child: MiniPlayer()
      ),
    );
  }
}

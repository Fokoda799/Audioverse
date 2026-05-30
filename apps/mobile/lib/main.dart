import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Audioverse/core/router/app_router.dart';
import 'package:Audioverse/core/theme/theme.dart';

void main() {
  runApp(const ProviderScope(child: AudioVerseApp()));
}

class AudioVerseApp extends StatelessWidget {
  const AudioVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
    );
  }
}
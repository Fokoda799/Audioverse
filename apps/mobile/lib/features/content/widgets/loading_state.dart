import 'package:flutter/material.dart';
import 'package:Audioverse/core/widgets/widgets.dart';

// LoadingState
//
// Centered spinner shown while SearchProvider.isLoading is true.
// Trivial widget, but split into its own file so search_screen.dart's
// _buildBody switch statement reads as a list of named states rather
// than a mix of inline widget trees of wildly different sizes.
//
// loading_state.dart

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppLoader(size: 32, strokeWidth: 2.5),
    );
  }
}

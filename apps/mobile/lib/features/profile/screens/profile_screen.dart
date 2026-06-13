import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Audioverse/features/profile/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  void initState() {
    super.initState();
    // Load profile when screen opens — only if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProfileProvider>();
      provider.loadProfile();
      // if (provider.profile == null) {
      //   provider.loadProfile();
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();

    if (profile.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile.errorMessage != null) {
      return Scaffold(
        body: Center(child: Text(profile.errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsetsGeometry.symmetric(vertical: 40.0),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 48,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? const Icon(Icons.person, size: 48)
                    : null,
              ),

              // Display name
              Text(
                profile.displayName ?? 'No name set',
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              // Bio
              if (profile.bio != null)
                Text(profile.bio!),

              // Preferences
              // SwitchListTile(
              //   title: const Text('Autoplay'),
              //   value: profile.preferences.autoplay,
              //   onChanged: (value) {
              //     context.read<ProfileProvider>().updatePreferences(
              //       profile.preferences.copyWith(autoplay: value),
              //     );
              //   },
              // ),
              //
              // SwitchListTile(
              //   title: const Text('Notifications'),
              //   value: profile.preferences.notifications,
              //   onChanged: (value) {
              //     context.read<ProfileProvider>().updatePreferences(
              //       profile.preferences.copyWith(notifications: value),
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }
}


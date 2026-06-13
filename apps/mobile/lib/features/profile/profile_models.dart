// Profile Models
// Pure Dart data classes â€” no Flutter, no Dio, no external dependencies.
// These are the shapes of data that flow through the profile feature.

class Profile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final UserPreferences? preferences;

  const Profile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.preferences,
  });

  /// Build from the JSON your NestJS server returns.
  /// Match the exact key names your API sends (camelCase for NestJS default).
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id:          json['id'] as String,
      displayName: json['display-name'] as String?,
      avatarUrl:   json['avatar-url'] as String?,
      bio:         json['bio'] as String?,
      preferences: UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'display-name': displayName,
    'avatar-url':   avatarUrl,
    'bio':         bio,
    'preferences': preferences,
  };

  @override
  String toString() => 'Profile(id: $id)';
}


class UserPreferences {
  final String theme;           // 'light' | 'dark' | 'system'
  final double playbackSpeed;   // 0.5 | 1.0 | 1.25 | 1.5 | 2.0
  final bool   autoplay;
  final bool   notifications;

  const UserPreferences({
    this.theme         = 'system',
    this.playbackSpeed = 1.0,
    this.autoplay      = true,
    this.notifications = true,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme:         json['theme']         as String? ?? 'system',
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      autoplay:      json['autoplay']      as bool?   ?? true,
      notifications: json['notifications'] as bool?   ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'theme':         theme,
    'playbackSpeed': playbackSpeed,
    'autoplay':      autoplay,
    'notifications': notifications,
  };

  UserPreferences copyWith({
    String? theme,
    double? playbackSpeed,
    bool?   autoplay,
    bool?   notifications,
  }) {
    return UserPreferences(
      theme:         theme         ?? this.theme,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      autoplay:      autoplay      ?? this.autoplay,
      notifications: notifications ?? this.notifications,
    );
  }
}

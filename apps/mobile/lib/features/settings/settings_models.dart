class UserPreferences {
  final String theme;           // 'light' | 'dark' | 'system'
  final double playbackSpeed;   // 0.5 | 1.0 | 1.25 | 1.5 | 2.0
  final bool   autoplay;
  final String? downloadQuality;
  final Map<String?, bool>   notifications;

  const UserPreferences({
    this.theme         = 'system',
    this.playbackSpeed = 1.0,
    this.autoplay      = true,
    this.downloadQuality = "medium",
    this.notifications = const {
      "new_releases": false,
      "download_complete": false,
      "recommendations": false
    },
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme:         json['theme']         as String? ?? 'system',
      playbackSpeed: (json['playback-speed'] as num?)?.toDouble() ?? 1.0,
      autoplay:      json['autoplay']      as bool?   ?? true,
      downloadQuality: json['download-quality'] as String? ?? 'medium',
      notifications: json['notifications'] != null
          ? Map<String, bool>.from(json['notifications'] as Map)
          : const {
        "new_releases": false,
        "download_complete": false,
        "recommendations": false
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'theme':         theme,
    'playback-speed': playbackSpeed,
    'autoplay':      autoplay,
    'download-quality': downloadQuality,
    'notifications': notifications,
  };

  UserPreferences copyWith({
    String? theme,
    double? playbackSpeed,
    bool?   autoplay,
    String? downloadQuality,
    Map<String, bool>?   notifications,
  }) {
    return UserPreferences(
      theme:         theme         ?? this.theme,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      autoplay:      autoplay      ?? this.autoplay,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      notifications: notifications ?? this.notifications,
    );
  }
}


// Profile Models
// Pure Dart data classes â€” no Flutter, no Dio, no external dependencies.
// These are the shapes of data that flow through the profile feature.

class Profile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? createdAt;

  const Profile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.createdAt,
  });

  /// Build from the JSON your NestJS server returns.
  /// Match the exact key names your API sends (camelCase for NestJS default).
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id:          json['id'] as String,
      displayName: json['display-name'] as String?,
      avatarUrl:   json['avatar-url'] as String?,
      bio:         json['bio'] as String?,
      createdAt:         json['created-at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id':          id,
    'display-name': displayName,
    'avatar-url':   avatarUrl,
    'bio':         bio,
    'createdAt': createdAt,
  };

  Profile copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt
    );
  }

  @override
  String toString() => 'Profile(id: $id)';
}

class UpdateProfileRequest {
  final String? displayName;
  final String? bio;
  final String? avatarUrl;

  const UpdateProfileRequest({
    this.displayName,
    this.bio,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
    if (displayName != null) 'displayName': displayName,
    if (bio != null) 'bio': bio,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };
}


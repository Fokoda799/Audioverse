class User {
  final String  id;
  final String  name;
  final String  email;
  final String  role;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Server sends "created-at" as {} (empty object) — broken backend serialization.
    // We try all key casings and fall back to DateTime.now() if unparseable.
    final rawDate = json['created-at']   // kebab-case (current server)
        ?? json['createdAt']    // camelCase  (after backend fix)
        ?? json['created_at'];  // snake_case (just in case)

    final createdAt = rawDate is String
        ? DateTime.tryParse(rawDate) ?? DateTime.now()
        : DateTime.now(); // {} is not a String, so we land here safely

    return User(
      id:        json['id']    as String,
      name:      json['name']  as String,
      email:     json['email'] as String,
      role:      json['role']  as String? ?? 'USER',
      avatarUrl: (json['avatar-url']   // kebab-case  (current server)
          ?? json['avatarUrl']    // camelCase   (after backend fix)
          ?? json['avatar_url'])  // snake_case  (just in case)
      as String?,
      createdAt: createdAt,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  String toString() => 'User(id: $id, name: $name, email: $email, role: $role)';
}

class AuthToken {
  final String   accessToken;
  final String   refreshToken;
  final DateTime expiresAt;

  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken:  json['access-token']  as String,
      refreshToken: json['refresh-token'] as String,
      expiresAt: DateTime.now().add(
        Duration(seconds: json['expires_in'] as int),
      ),
    );
  }

  bool get isValid   => DateTime.now().isBefore(expiresAt);
  bool get isExpired => !isValid;

  @override
  String toString() => 'AuthToken(expiresAt: $expiresAt, isValid: $isValid)';
}

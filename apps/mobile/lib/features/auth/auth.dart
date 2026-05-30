// Auth Model
// Holds the data shape + JSON parsing for auth feature.

class Auth {
  final String id;
  // TODO: add your fields here

  const Auth({
    required this.id,
  });

  factory Auth.fromJson(Map<String, dynamic> json) {
    return Auth(
      id: json['id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
  };
}

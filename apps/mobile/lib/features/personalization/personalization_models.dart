// Personalization Models
// Pure Dart data classes â€” no Flutter, no Dio, no external dependencies.
// These are the shapes of data that flow through the personalization feature.

class Personalization {
  final String id;
  // TODO: add your fields here

  const Personalization({
    required this.id,
  });

  /// Build from the JSON your NestJS server returns.
  /// Match the exact key names your API sends (camelCase for NestJS default).
  factory Personalization.fromJson(Map<String, dynamic> json) {
    return Personalization(
      id: json['id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
  };

  @override
  String toString() => 'Personalization(id: )';
}

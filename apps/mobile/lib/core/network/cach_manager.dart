import 'package:hive_ce/hive.dart';

class CacheManager {
  static const ttl = Duration(minutes: 10);

  Future<T?> get<T>(
      Box box,
      String key,
      T Function(dynamic json) fromJson,
      ) async {
    final cached = box.get(key);

    if (cached == null) return null;

    final timestamp = DateTime.parse(cached['timestamp']);

    if (DateTime.now().difference(timestamp) > ttl) {
      return null;
    }

    final data = cached['data'];

    if (data == null) return null;

    return fromJson(data);
  }

  Future<void> save(
      Box box,
      String key,
      dynamic data,
      ) async {
    await box.put(key, {
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    });
  }
}
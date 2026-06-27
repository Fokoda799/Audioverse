// ── HistoryModel ─────────────────────────────────────────────────────────
//
// Wraps a Content with its progress data — same shape and same reasoning
// as ContinueListeningItem from the earlier Home delivery, but this is
// now the SINGLE canonical version. The Home feature's own
// ContinueListeningItem class should be deleted once this is wired in;
// HistoryRepository is the real source of this data, so there's no
// reason for two separate "content + progress" classes to exist.
import 'package:Audioverse/features/content/models/category_model.dart';
import 'package:Audioverse/features/content/models/content_models.dart';

class History {
  const History({
    required this.content,
    required this.positionSec,
    required this.progressPercent,
    required this.completed,
    required this.lastPlayedAt,
  });

  final Content content;
  final int positionSec;
  final double progressPercent;
  final bool completed;
  final DateTime lastPlayedAt;

  /// 0.0–1.0 scale — convenience getter for widgets like
  /// LinearProgressIndicator that expect a fractional value rather than
  /// the backend's 0–100 scale.
  double get progressFraction => (progressPercent / 100).clamp(0.0, 1.0);

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      content: Content.fromJson(json['content'] as Map<String, dynamic>),
      positionSec: json['position-sec'] as int,
      // Prisma Decimal can serialize as either a numeric value or a
      // string, depending on the serialization path, so parse both.
      progressPercent: json['progress-percent'] is num
          ? (json['progress-percent'] as num).toDouble()
          : double.parse(json['progress-percent'].toString()),
      completed: json['completed'] as bool,
      lastPlayedAt: DateTime.parse(json['last-played-at'] as String),
    );
  }
}

// ── PaginatedHistory ─────────────────────────────────────────────────────
class PaginatedHistory {
  const PaginatedHistory({required this.items, required this.meta});

  final List<History> items;
  final PaginationMeta meta;
}

// ProfileStats
//
// ⚠️ STUB — backend does not compute these yet. This file exists so
// ProfileScreen has a concrete type to build against today, without
// faking a working API call underneath it.
//
// What's stubbed vs. real:
//   - hoursListened, booksCompleted: hardcoded to 0 below. Computing
//     these for real means either:
//       (a) a dedicated backend endpoint (e.g. GET /profile/stats) that
//           aggregates ListeningHistory server-side (SUM positionSec
//           where completed, COUNT where completed=true), OR
//       (b) deriving them client-side from HistoryProvider.items once
//           pagination is fully loaded — fragile, since it requires
//           walking every page rather than one cheap aggregate query.
//     Option (a) is the right long-term fix; this file does NOT attempt
//     option (b) since it would silently produce wrong numbers on any
//     account with more than one page of history.
//
//   - favoritesCount: this one IS easy to make real right now without
//     any new backend work — FavoritesProvider.favoritedIds.length is
//     already loaded and correct. See ProfileScreen below for where
//     this gets pulled from FavoritesProvider directly instead of from
//     this stub class.
//
// profile_stats.dart

class ProfileStats {
  const ProfileStats({
    required this.hoursListened,
    required this.booksCompleted,
  });

  final double hoursListened;
  final int booksCompleted;

  // Hardcoded zero-state — replace with a real value the moment
  // GET /profile/stats (or equivalent) exists on the backend.
  factory ProfileStats.stub() => const ProfileStats(
    hoursListened: 0,
    booksCompleted: 0,
  );
}

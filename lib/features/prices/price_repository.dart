import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rocis_recipes/features/prices/price_snapshot.dart';

/// Where fresh snapshots come from (the `data` branch of the project repo).
final Uri kSnapshotUrl = Uri.parse(
  'https://raw.githubusercontent.com/RoeeIlouz/ROCIsRecipes/data/snapshot.json.gz',
);

/// Refresh when the snapshot in use is older than this.
const Duration kRefreshAfter = Duration(days: 3);

/// Warn when the snapshot in use is older than this.
const Duration kStaleAfter = Duration(days: 7);

abstract class SnapshotSource {
  /// Returns the raw gzip bytes, or null when unavailable. Never throws.
  Future<List<int>?> fetch();
}

class HttpSnapshotSource implements SnapshotSource {
  HttpSnapshotSource(this.url, this.client);

  final Uri url;
  final http.Client client;

  @override
  Future<List<int>?> fetch() async {
    try {
      final response = await client
          .get(url)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200 ? response.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }
}

class PriceRepository extends ChangeNotifier {
  PriceRepository({
    required PriceSnapshot bundled,
    required this.source,
    required this.cacheDir,
  }) : _snapshot = bundled;

  final SnapshotSource source;
  final Directory cacheDir;
  PriceSnapshot _snapshot;

  File get _cacheFile => File('${cacheDir.path}/snapshot.json.gz');

  PriceSnapshot get snapshot => _snapshot;

  bool isStale(DateTime now) => _snapshot.isOlderThan(kStaleAfter, now);

  /// Uses the cached snapshot when it is newer than the bundled one.
  Future<void> init() async {
    try {
      if (await _cacheFile.exists()) {
        final cached = PriceSnapshot.fromGzipBytes(
          await _cacheFile.readAsBytes(),
        );
        if (cached.generatedAt.isAfter(_snapshot.generatedAt))
          _snapshot = cached;
      }
    } catch (_) {
      // A damaged cache file is ignored; the bundled snapshot stays in use.
    }
  }

  /// Downloads a fresh snapshot when the current one is older than [kRefreshAfter].
  /// Any failure (offline, corrupt, older data) keeps the current snapshot.
  Future<void> refreshIfNeeded(DateTime now) async {
    if (!_snapshot.isOlderThan(kRefreshAfter, now)) return;
    final bytes = await source.fetch();
    if (bytes == null) return;
    try {
      final fresh = PriceSnapshot.fromGzipBytes(bytes);
      if (!fresh.generatedAt.isAfter(_snapshot.generatedAt)) return;
      await cacheDir.create(recursive: true);
      await _cacheFile.writeAsBytes(bytes, flush: true);
      _snapshot = fresh;
      notifyListeners();
    } catch (_) {
      // Corrupt or truncated download: keep what we have.
    }
  }
}

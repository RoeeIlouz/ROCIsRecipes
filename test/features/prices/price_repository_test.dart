import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/prices/price_repository.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';

Map<String, dynamic> _json(String generatedAt, {num eggPrice = 12.9}) => {
  'version': 1,
  'generatedAt': generatedAt,
  'currency': 'ILS',
  'chains': [
    {'id': 'shufersal', 'nameHe': 'שופרסל', 'nameEn': 'Shufersal'},
  ],
  'stores': [
    {
      'id': 'shufersal:7',
      'chain': 'shufersal',
      'name': 'שלי 7',
      'address': 'הרצל 5, תל אביב',
      'lat': 32.0853,
      'lng': 34.7818,
      'prices': {'egg': eggPrice},
    },
  ],
};

List<int> _gz(Map<String, dynamic> json) =>
    gzip.encode(utf8.encode(jsonEncode(json)));

class _FakeSource implements SnapshotSource {
  _FakeSource(this.bytes);

  List<int>? bytes;
  int calls = 0;

  @override
  Future<List<int>?> fetch() async {
    calls++;
    return bytes;
  }
}

void main() {
  late Directory dir;
  final now = DateTime(2026, 11, 9, 12);

  setUp(() => dir = Directory.systemTemp.createTempSync('rocis_prices_'));
  tearDown(() => dir.deleteSync(recursive: true));

  PriceSnapshot bundled(String date) => PriceSnapshot.fromJson(_json(date));

  group('PriceSnapshot', () {
    test('fromJson parses the builder output shape', () {
      final s = PriceSnapshot.fromJson(_json('2026-11-09', eggPrice: 13));
      expect(s.generatedAt, DateTime(2026, 11, 9));
      expect(s.chains.single.nameHe, 'שופרסל');
      final store = s.stores.single;
      expect(store.id, 'shufersal:7');
      expect(store.chainId, 'shufersal');
      expect(store.lat, 32.0853);
      expect(store.prices['egg'], 13.0);
    });

    test('fromGzipBytes round-trips the builder output shape', () {
      final s = PriceSnapshot.fromGzipBytes(_gz(_json('2026-11-09')));
      expect(s.stores.single.address, 'הרצל 5, תל אביב');
    });

    test('isOlderThan is false at exactly the limit and true just past it', () {
      final s = bundled('2026-11-06');
      expect(
        s.isOlderThan(const Duration(days: 3), DateTime(2026, 11, 9)),
        isFalse,
      );
      expect(
        s.isOlderThan(const Duration(days: 3), DateTime(2026, 11, 9, 0, 1)),
        isTrue,
      );
    });
  });

  group('PriceRepository', () {
    test('uses the bundled snapshot when no cache exists', () async {
      final repo = PriceRepository(
        bundled: bundled('2026-11-01'),
        source: _FakeSource(null),
        cacheDir: dir,
      );
      await repo.init();
      expect(repo.snapshot.generatedAt, DateTime(2026, 11, 1));
    });

    test(
      'refresh replaces the snapshot when the download is newer and caches it',
      () async {
        final source = _FakeSource(_gz(_json('2026-11-08', eggPrice: 14.5)));
        final repo = PriceRepository(
          bundled: bundled('2026-11-01'),
          source: source,
          cacheDir: dir,
        );
        await repo.init();
        await repo.refreshIfNeeded(now);
        expect(repo.snapshot.generatedAt, DateTime(2026, 11, 8));
        expect(repo.snapshot.stores.single.prices['egg'], 14.5);

        final reopened = PriceRepository(
          bundled: bundled('2026-11-01'),
          source: _FakeSource(null),
          cacheDir: dir,
        );
        await reopened.init();
        expect(reopened.snapshot.generatedAt, DateTime(2026, 11, 8));
      },
    );

    test(
      'corrupt download keeps the current snapshot and writes no cache',
      () async {
        final source = _FakeSource(utf8.encode('not gzip at all'));
        final repo = PriceRepository(
          bundled: bundled('2026-11-01'),
          source: source,
          cacheDir: dir,
        );
        await repo.init();
        await repo.refreshIfNeeded(now);
        expect(repo.snapshot.generatedAt, DateTime(2026, 11, 1));
        expect(dir.listSync(), isEmpty);
      },
    );

    test('truncated gzip keeps the current snapshot', () async {
      final full = _gz(_json('2026-11-08'));
      final repo = PriceRepository(
        bundled: bundled('2026-11-01'),
        source: _FakeSource(full.sublist(0, full.length ~/ 2)),
        cacheDir: dir,
      );
      await repo.init();
      await repo.refreshIfNeeded(now);
      expect(repo.snapshot.generatedAt, DateTime(2026, 11, 1));
    });

    test(
      'network failure keeps the snapshot and reports stale when over 7 days',
      () async {
        final repo = PriceRepository(
          bundled: bundled('2026-10-20'),
          source: _FakeSource(null),
          cacheDir: dir,
        );
        await repo.init();
        await repo.refreshIfNeeded(now);
        expect(repo.snapshot.generatedAt, DateTime(2026, 10, 20));
        expect(repo.isStale(now), isTrue);
      },
    );

    test('is not stale when the snapshot is under 7 days old', () async {
      final repo = PriceRepository(
        bundled: bundled('2026-11-05'),
        source: _FakeSource(null),
        cacheDir: dir,
      );
      await repo.init();
      expect(repo.isStale(now), isFalse);
    });

    test(
      'no download is attempted when the snapshot is under 3 days old',
      () async {
        final source = _FakeSource(_gz(_json('2026-11-09')));
        final repo = PriceRepository(
          bundled: bundled('2026-11-08'),
          source: source,
          cacheDir: dir,
        );
        await repo.init();
        await repo.refreshIfNeeded(now);
        expect(source.calls, 0);
      },
    );

    test('an older download never replaces a newer snapshot', () async {
      final source = _FakeSource(_gz(_json('2026-10-01')));
      final repo = PriceRepository(
        bundled: bundled('2026-11-01'),
        source: source,
        cacheDir: dir,
      );
      await repo.init();
      await repo.refreshIfNeeded(now);
      expect(repo.snapshot.generatedAt, DateTime(2026, 11, 1));
    });

    test(
      'a corrupt cache file is ignored in favour of the bundled snapshot',
      () async {
        File('${dir.path}/snapshot.json.gz').writeAsBytesSync([1, 2, 3]);
        final repo = PriceRepository(
          bundled: bundled('2026-11-01'),
          source: _FakeSource(null),
          cacheDir: dir,
        );
        await repo.init();
        expect(repo.snapshot.generatedAt, DateTime(2026, 11, 1));
      },
    );
  });
}

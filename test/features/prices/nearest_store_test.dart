import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' show LocationPermission;
import 'package:rocis_recipes/features/prices/location_provider.dart';
import 'package:rocis_recipes/features/prices/nearest_store.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';

PriceStore _store(String id, String chain, double lat, double lng) => PriceStore(
      id: id,
      chainId: chain,
      name: id,
      address: 'x',
      lat: lat,
      lng: lng,
      prices: const {},
    );

void main() {
  // Tel Aviv city centre.
  const lat = 32.0853, lng = 34.7818;

  test('haversine between Tel Aviv and Jerusalem is about 54 km', () {
    expect(haversineKm(32.0853, 34.7818, 31.7683, 35.2137), closeTo(54, 2));
  });

  test('haversine of a point with itself is zero', () {
    expect(haversineKm(lat, lng, lat, lng), closeTo(0, 0.001));
  });

  test('nearest picks the closest branch of the requested chain only', () {
    final stores = [
      _store('shufersal:far', 'shufersal', 32.3, 34.9),
      _store('shufersal:near', 'shufersal', 32.09, 34.79),
      _store('carrefour:nearest', 'carrefour', 32.0854, 34.7819),
    ];
    final result = nearestStore(stores, 'shufersal', lat, lng)!;
    expect(result.store.id, 'shufersal:near');
    expect(result.distanceKm, lessThan(2));
  });

  test('ignores stores of other chains', () {
    final stores = [_store('carrefour:1', 'carrefour', lat, lng)];
    expect(nearestStore(stores, 'shufersal', lat, lng), isNull);
  });

  test('returns null when every branch is farther than 50 km', () {
    // Eilat is roughly 280 km from Tel Aviv.
    final stores = [_store('shufersal:eilat', 'shufersal', 29.5577, 34.9519)];
    expect(nearestStore(stores, 'shufersal', lat, lng), isNull);
  });

  test('maxKm can be widened', () {
    final stores = [_store('shufersal:eilat', 'shufersal', 29.5577, 34.9519)];
    expect(nearestStore(stores, 'shufersal', lat, lng, maxKm: 400)?.store.id, 'shufersal:eilat');
  });

  test('empty store list gives null', () {
    expect(nearestStore(const [], 'shufersal', lat, lng), isNull);
  });

  group('statusFromPermission', () {
    test('service off wins over any permission', () {
      expect(statusFromPermission(LocationPermission.whileInUse, serviceEnabled: false), LocationStatus.serviceOff);
    });

    test('maps permissions to statuses', () {
      expect(statusFromPermission(LocationPermission.whileInUse, serviceEnabled: true), LocationStatus.granted);
      expect(statusFromPermission(LocationPermission.always, serviceEnabled: true), LocationStatus.granted);
      expect(statusFromPermission(LocationPermission.denied, serviceEnabled: true), LocationStatus.denied);
      expect(statusFromPermission(LocationPermission.deniedForever, serviceEnabled: true), LocationStatus.deniedForever);
      expect(statusFromPermission(LocationPermission.unableToDetermine, serviceEnabled: true), LocationStatus.unavailable);
    });
  });
}

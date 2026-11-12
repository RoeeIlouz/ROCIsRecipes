import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/features/prices/location_provider.dart';
import 'package:rocis_recipes/features/prices/nearby_controller.dart';

import '../helpers/test_env.dart';

void main() {
  test('a remembered location is used again without asking', () {
    final c = NearbyController(
      FakeLocationProvider(),
      initialLocation: const UserLocation(lat: 32.1, lng: 34.8),
      initialLabel: 'Ramat Gan',
    );
    expect(c.location!.lat, 32.1);
    expect(c.status, LocationStatus.granted);
    expect(c.manualLabel, 'Ramat Gan');
  });

  test('a chosen area is passed on to be remembered', () {
    UserLocation? saved;
    String? label;
    final c = NearbyController(
      FakeLocationProvider(),
      onSaved: (l, text) {
        saved = l;
        label = text;
      },
    );
    c.setManual(const UserLocation(lat: 31.9, lng: 34.7), 'Rehovot');
    expect(saved!.lat, 31.9);
    expect(label, 'Rehovot');
  });

  test('a found position is passed on without an area name', () async {
    UserLocation? saved;
    String? label = 'stale';
    final c = NearbyController(
      FakeLocationProvider(location: const UserLocation(lat: 32.0, lng: 34.9)),
      onSaved: (l, text) {
        saved = l;
        label = text;
      },
    );
    await c.locate();
    expect(saved!.lng, 34.9);
    expect(label, isNull);
  });

  test('the settings keep the last location and can forget it', () async {
    final env = await TestEnv.create();
    expect(env.settings.savedLocation, isNull);
    await env.settings.setSavedLocation(
      const UserLocation(lat: 32.0, lng: 34.8),
      'Tel Aviv',
    );
    final saved = env.settings.savedLocation!;
    expect(saved.location.lat, 32.0);
    expect(saved.label, 'Tel Aviv');
    await env.settings.setSavedLocation(null, null);
    expect(env.settings.savedLocation, isNull);
  });
}

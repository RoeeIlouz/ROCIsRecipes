import 'package:flutter/foundation.dart';
import 'package:rocis_recipes/features/prices/location_provider.dart';

/// Holds the result of asking for the user's location. Nothing is requested
/// until [locate] is called, and the position never leaves the device.
class NearbyController extends ChangeNotifier {
  NearbyController(this._provider);

  final LocationProvider _provider;

  LocationStatus? status;
  UserLocation? location;
  bool loading = false;

  Future<void> locate() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    var result = await _provider.requestPermission();
    UserLocation? position;
    if (result == LocationStatus.granted) {
      position = await _provider.currentLocation();
      if (position == null) result = LocationStatus.unavailable;
    }
    status = result;
    location = position;
    loading = false;
    notifyListeners();
  }
}

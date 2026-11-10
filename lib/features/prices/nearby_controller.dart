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

  /// Name of the area picked by hand, when the user did not share the device location.
  String? manualLabel;

  /// Uses a point chosen by hand (the position never leaves the device).
  void setManual(UserLocation point, String label) {
    location = point;
    status = LocationStatus.granted;
    manualLabel = label;
    notifyListeners();
  }

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
    manualLabel = null;
    loading = false;
    notifyListeners();
  }
}

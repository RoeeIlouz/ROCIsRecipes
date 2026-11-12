import 'package:flutter/foundation.dart';
import 'package:rocis_recipes/features/prices/location_provider.dart';

/// Holds the result of asking for the user's location. Nothing is requested
/// until [locate] is called, and the position never leaves the device.
class NearbyController extends ChangeNotifier {
  NearbyController(
    this._provider, {
    UserLocation? initialLocation,
    String? initialLabel,
    this.onSaved,
  }) {
    if (initialLocation != null) {
      location = initialLocation;
      manualLabel = initialLabel;
      status = LocationStatus.granted;
    }
  }

  final LocationProvider _provider;

  /// Called with the position (and the area name, when picked by hand) so it can be kept on this
  /// device and used again next time. It is never sent anywhere.
  final void Function(UserLocation? location, String? label)? onSaved;

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
    onSaved?.call(point, label);
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
    if (position != null) onSaved?.call(position, null);
    loading = false;
    notifyListeners();
  }
}

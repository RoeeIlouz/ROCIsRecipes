import 'package:geolocator/geolocator.dart';

enum LocationStatus { granted, denied, deniedForever, serviceOff, unavailable }

class UserLocation {
  const UserLocation({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

/// Source of the user's position. Coarse location only; the position stays on the device.
abstract class LocationProvider {
  /// Asks for permission when needed and reports the resulting status.
  Future<LocationStatus> requestPermission();

  /// The current position, or null when it cannot be determined.
  Future<UserLocation?> currentLocation();
}

LocationStatus statusFromPermission(
  LocationPermission permission, {
  required bool serviceEnabled,
}) {
  if (!serviceEnabled) return LocationStatus.serviceOff;
  return switch (permission) {
    LocationPermission.whileInUse ||
    LocationPermission.always => LocationStatus.granted,
    LocationPermission.denied => LocationStatus.denied,
    LocationPermission.deniedForever => LocationStatus.deniedForever,
    LocationPermission.unableToDetermine => LocationStatus.unavailable,
  };
}

class GeolocatorLocationProvider implements LocationProvider {
  @override
  Future<LocationStatus> requestPermission() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return statusFromPermission(permission, serviceEnabled: enabled);
    } catch (_) {
      return LocationStatus.unavailable;
    }
  }

  @override
  Future<UserLocation?> currentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return UserLocation(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return null;
    }
  }
}

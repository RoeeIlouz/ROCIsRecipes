import 'dart:math' as math;

import 'package:rocis_recipes/features/prices/price_snapshot.dart';

const double _earthRadiusKm = 6371.0;

/// Great-circle distance between two points in kilometres.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
}

class NearestResult {
  const NearestResult({required this.store, required this.distanceKm});

  final PriceStore store;
  final double distanceKm;
}

/// The closest branch of [chainId] to the given position, or null when the
/// chain has no branch within [maxKm] (so a far-away branch is never presented
/// as "nearest").
NearestResult? nearestStore(
  List<PriceStore> stores,
  String chainId,
  double lat,
  double lng, {
  double maxKm = 50,
}) {
  NearestResult? best;
  for (final store in stores) {
    if (store.chainId != chainId) continue;
    final d = haversineKm(lat, lng, store.lat, store.lng);
    if (d > maxKm) continue;
    if (best == null || d < best.distanceKm)
      best = NearestResult(store: store, distanceKm: d);
  }
  return best;
}

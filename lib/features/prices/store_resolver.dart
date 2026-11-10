import 'package:rocis_recipes/features/prices/location_provider.dart';
import 'package:rocis_recipes/features/prices/nearest_store.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';

/// How the branch for a chain was chosen.
enum StoreSource { gps, manual, tooFar, none }

class ResolvedStore {
  const ResolvedStore({required this.chainId, required this.store, required this.distanceKm, required this.source});

  final String chainId;
  final PriceStore? store;
  final double? distanceKm;
  final StoreSource source;
}

/// Picks one branch per chain: the nearest one when the position is known,
/// otherwise (or when none is close enough) the branch the user chose by hand.
List<ResolvedStore> resolveStores({
  required PriceSnapshot snapshot,
  required UserLocation? location,
  required Map<String, String> manual,
}) {
  return [
    for (final chain in snapshot.chains)
      () {
        if (location != null) {
          final nearest = nearestStore(snapshot.stores, chain.id, location.lat, location.lng);
          if (nearest != null) {
            return ResolvedStore(
              chainId: chain.id,
              store: nearest.store,
              distanceKm: nearest.distanceKm,
              source: StoreSource.gps,
            );
          }
        }
        final chosen = manual[chain.id];
        final store = chosen == null
            ? null
            : snapshot.stores.where((s) => s.id == chosen && s.chainId == chain.id).firstOrNull;
        if (store != null) {
          return ResolvedStore(chainId: chain.id, store: store, distanceKm: null, source: StoreSource.manual);
        }
        return ResolvedStore(
          chainId: chain.id,
          store: null,
          distanceKm: null,
          source: location != null ? StoreSource.tooFar : StoreSource.none,
        );
      }(),
  ];
}

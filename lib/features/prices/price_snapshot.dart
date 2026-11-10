import 'dart:convert';
import 'dart:io';

class PriceChain {
  const PriceChain({required this.id, required this.nameHe, required this.nameEn});

  final String id;
  final String nameHe;
  final String nameEn;

  factory PriceChain.fromJson(Map<String, dynamic> json) => PriceChain(
        id: json['id'] as String,
        nameHe: json['nameHe'] as String,
        nameEn: json['nameEn'] as String,
      );
}

class PriceStore {
  const PriceStore({
    required this.id,
    required this.chainId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.prices,
  });

  final String id;
  final String chainId;
  final String name;
  final String address;
  final double lat;
  final double lng;

  /// Ingredient id to estimated price in NIS (per kilogram for weighted items).
  final Map<String, double> prices;

  factory PriceStore.fromJson(Map<String, dynamic> json) => PriceStore(
        id: json['id'] as String,
        chainId: json['chain'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        prices: {
          for (final e in (json['prices'] as Map).entries) e.key as String: (e.value as num).toDouble(),
        },
      );
}

class PriceSnapshot {
  const PriceSnapshot({required this.generatedAt, required this.chains, required this.stores});

  final DateTime generatedAt;
  final List<PriceChain> chains;
  final List<PriceStore> stores;

  factory PriceSnapshot.fromJson(Map<String, dynamic> json) => PriceSnapshot(
        generatedAt: DateTime.parse(json['generatedAt'] as String),
        chains: (json['chains'] as List)
            .map((e) => PriceChain.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        stores: (json['stores'] as List)
            .map((e) => PriceStore.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  /// Parses the gzip-compressed JSON written by tools/price_pipeline.
  /// Throws a [FormatException] or [ArgumentError] on corrupt or truncated data.
  factory PriceSnapshot.fromGzipBytes(List<int> bytes) {
    final text = utf8.decode(gzip.decode(bytes));
    return PriceSnapshot.fromJson(Map<String, dynamic>.from(jsonDecode(text) as Map));
  }

  bool isOlderThan(Duration age, DateTime now) => now.difference(generatedAt) > age;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/prices/location_provider.dart';
import 'package:rocis_recipes/features/prices/nearby_controller.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/prices/ui/area_picker_sheet.dart';
import 'package:rocis_recipes/features/prices/ui/price_summary.dart';
import 'package:rocis_recipes/features/shopping/shopping_repository.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';
import 'package:rocis_recipes/shared/ui/widgets/glass_container.dart';

/// Where to shop: the nearest branch of every chain, closest first, the cheapest chain for the current
/// shopping list marked, and a button to navigate there. The position stays on the device.
class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final view = PriceViewData.of(context);
    final nearby = context.watch<NearbyController>();
    final hasItems = context.watch<ShoppingRepository>().items.any(
      (e) => !e.checked,
    );
    final cheapestId = hasItems ? view.cheapest?.chainId : null;
    final money = currencyFormat(context);
    final isHebrew = Localizations.localeOf(context).languageCode == 'he';

    // Closest first; chains with no branch known come last.
    final order = [for (var i = 0; i < view.resolved.length; i++) i]
      ..sort((a, b) {
        final da = view.resolved[a].distanceKm;
        final db = view.resolved[b].distanceKm;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              if (nearby.status == null)
                OutlinedButton.icon(
                  key: const Key('stores_use_location'),
                  onPressed: nearby.loading ? null : nearby.locate,
                  icon: const Icon(Icons.my_location_rounded),
                  label: Text(l10n.useMyLocation),
                ),
              TextButton.icon(
                key: const Key('stores_choose_area'),
                onPressed: () async {
                  final picked = await showModalBottomSheet<PriceStore>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) =>
                        AreaPickerSheet(stores: view.snapshot.stores),
                  );
                  if (picked != null) {
                    nearby.setManual(
                      UserLocation(lat: picked.lat, lng: picked.lng),
                      picked.address,
                    );
                  }
                },
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: Text(l10n.chooseArea),
              ),
            ],
          ),
          if (nearby.status != null && nearby.status != LocationStatus.granted)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.locationUnavailable),
            ),
          if (nearby.manualLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.usingArea(nearby.manualLabel!)),
            ),
          const SizedBox(height: 12),
          for (final i in order)
            () {
              final resolved = view.resolved[i];
              final total = view.totals[i];
              final chain = view.snapshot.chains.firstWhere(
                (c) => c.id == resolved.chainId,
              );
              final store = resolved.store;
              return Padding(
                key: Key('store_card_${chain.id}'),
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  enableGlass: false,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isHebrew ? chain.nameHe : chain.nameEn,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          if (chain.id == cheapestId)
                            Chip(
                              key: const Key('cheapest_badge'),
                              avatar: const Icon(
                                Icons.savings_outlined,
                                size: 18,
                              ),
                              label: Text(l10n.storesCheapest),
                            ),
                        ],
                      ),
                      if (store == null)
                        Text(
                          nearby.location == null
                              ? l10n.storesNeedLocation
                              : l10n.storesNoBranch,
                          key: Key('store_hint_${chain.id}'),
                        )
                      else ...[
                        Text(store.name),
                        Text(store.address, style: theme.textTheme.bodySmall),
                        if (resolved.distanceKm != null)
                          Text(
                            l10n.distanceKm(
                              resolved.distanceKm!.toStringAsFixed(1),
                            ),
                          ),
                        if (hasItems && total.hasData)
                          Text(
                            '${money.format(total.total)} ${l10n.estimateLabel}',
                            style: theme.textTheme.titleSmall,
                          ),
                        TextButton.icon(
                          key: Key('store_navigate_${chain.id}'),
                          onPressed: () => context.read<LaunchUrl>()(
                            Uri.https('www.google.com', '/maps/search/', {
                              'api': '1',
                              'query': store.address,
                            }),
                          ),
                          icon: const Icon(Icons.directions_rounded),
                          label: Text(l10n.navigate),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }(),
          Text(l10n.osmAttribution, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

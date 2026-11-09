import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:rocis_recipes/features/pantry/settings_repository.dart';
import 'package:rocis_recipes/features/prices/location_provider.dart';
import 'package:rocis_recipes/features/prices/nearby_controller.dart';
import 'package:rocis_recipes/features/prices/price_repository.dart';
import 'package:rocis_recipes/features/prices/price_service.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/features/prices/store_resolver.dart';
import 'package:rocis_recipes/features/shopping/shopping_item.dart';
import 'package:rocis_recipes/features/shopping/shopping_repository.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';
import 'package:rocis_recipes/shared/ui/widgets/glass_container.dart';

/// Opens a link outside the app (provided by the app root; replaced in tests).
typedef LaunchUrl = Future<bool> Function(Uri uri);

/// Everything the shopping list needs to show prices: the branch per chain,
/// the list total there, and the chain that best covers the list.
class PriceViewData {
  const PriceViewData({required this.snapshot, required this.resolved, required this.totals, required this.service});

  final PriceSnapshot snapshot;
  final List<ResolvedStore> resolved;
  final List<ChainTotal> totals;
  final PriceService service;

  ChainTotal? get cheapest => cheapestChain(totals);

  /// Estimated price of [item] at the best covering chain, or null.
  double? priceOf(ShoppingItem item) => service.priceOf(item, cheapest?.store);

  static PriceViewData of(BuildContext context) {
    final snapshot = context.watch<PriceRepository>().snapshot;
    final location = context.watch<NearbyController>().location;
    final manual = context.watch<SettingsRepository>().manualStoreIds;
    final items = context.watch<ShoppingRepository>().items;
    final service = context.read<PriceService>();
    final resolved = resolveStores(snapshot: snapshot, location: location, manual: manual);
    return PriceViewData(
      snapshot: snapshot,
      resolved: resolved,
      totals: [
        for (final r in resolved) service.totalFor(items, r.chainId, r.store, distanceKm: r.distanceKm),
      ],
      service: service,
    );
  }
}

NumberFormat currencyFormat(BuildContext context) =>
    NumberFormat.currency(locale: Localizations.localeOf(context).toString(), symbol: '₪', decimalDigits: 2);

class PriceSummary extends StatelessWidget {
  const PriceSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final view = PriceViewData.of(context);
    if (view.snapshot.chains.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final nearby = context.watch<NearbyController>();
    final repo = context.watch<PriceRepository>();
    final hasItems = context.watch<ShoppingRepository>().items.any((e) => !e.checked);
    final locale = Localizations.localeOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.pricesTitle, style: theme.textTheme.titleMedium),
            if (repo.isStale(DateTime.now()))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.staleWarning(DateFormat.yMd(locale.toString()).format(repo.snapshot.generatedAt)),
                  key: const Key('stale_warning'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 8),
            if (nearby.status == null)
              OutlinedButton.icon(
                key: const Key('use_location_button'),
                onPressed: nearby.loading ? null : nearby.locate,
                icon: const Icon(Icons.my_location_rounded),
                label: Text(l10n.useMyLocation),
              )
            else if (nearby.status != LocationStatus.granted)
              Text(l10n.locationUnavailable, key: const Key('location_unavailable')),
            for (var i = 0; i < view.resolved.length; i++)
              _ChainRow(
                chain: view.snapshot.chains.firstWhere((c) => c.id == view.resolved[i].chainId),
                resolved: view.resolved[i],
                total: view.totals[i],
                stores: view.snapshot.stores.where((s) => s.chainId == view.resolved[i].chainId).toList(),
                hasItems: hasItems,
              ),
            const SizedBox(height: 8),
            Text(l10n.osmAttribution, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ChainRow extends StatelessWidget {
  const _ChainRow({
    required this.chain,
    required this.resolved,
    required this.total,
    required this.stores,
    required this.hasItems,
  });

  final PriceChain chain;
  final ResolvedStore resolved;
  final ChainTotal total;
  final List<PriceStore> stores;
  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isHebrew = Localizations.localeOf(context).languageCode == 'he';
    final store = resolved.store;
    final needsPicker = resolved.source != StoreSource.gps;
    final manualId = context.watch<SettingsRepository>().manualStoreIds[chain.id];
    final sorted = [...stores]..sort((a, b) => a.name.compareTo(b.name));

    return Padding(
      key: Key('price_row_${chain.id}'),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isHebrew ? chain.nameHe : chain.nameEn, style: theme.textTheme.titleSmall),
          if (store != null) ...[
            Text(store.name),
            if (resolved.distanceKm != null) Text(l10n.distanceKm(resolved.distanceKm!.toStringAsFixed(1))),
            if (hasItems && total.hasData)
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    currencyFormat(context).format(total.total),
                    key: Key('price_total_${chain.id}'),
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(l10n.estimateLabel, style: theme.textTheme.bodySmall),
                ],
              ),
            if (hasItems && total.isPartial)
              Text(l10n.partialTotal(total.unpricedCount), key: Key('partial_${chain.id}')),
            if (hasItems && !total.hasData) Text(l10n.noPriceData, key: Key('no_data_${chain.id}')),
            TextButton.icon(
              key: Key('navigate_${chain.id}'),
              onPressed: () => context.read<LaunchUrl>()(
                Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': store.address}),
              ),
              icon: const Icon(Icons.directions_rounded),
              label: Text(l10n.navigate),
            ),
          ],
          if (resolved.source == StoreSource.tooFar)
            Text(l10n.tooFar(50), key: Key('too_far_${chain.id}')),
          if (needsPicker)
            DropdownButton<String>(
              key: Key('store_picker_${chain.id}'),
              isExpanded: true,
              hint: Text(l10n.pickBranch),
              value: sorted.any((s) => s.id == manualId) ? manualId : null,
              items: [
                for (final s in sorted) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (id) {
                if (id != null) context.read<SettingsRepository>().setManualStore(chain.id, id);
              },
            ),
        ],
      ),
    );
  }
}

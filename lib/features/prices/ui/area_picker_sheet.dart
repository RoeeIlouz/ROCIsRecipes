import 'package:flutter/material.dart';
import 'package:rocis_recipes/features/prices/price_snapshot.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

/// Lets the user pick an area by searching branch names and addresses (a city or a street).
/// Entirely offline: the chosen branch's coordinates become the reference point.
class AreaPickerSheet extends StatefulWidget {
  const AreaPickerSheet({super.key, required this.stores});

  final List<PriceStore> stores;

  @override
  State<AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<AreaPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = _query.trim();
    final matches = q.isEmpty
        ? const <PriceStore>[]
        : widget.stores
              .where((s) => s.name.contains(q) || s.address.contains(q))
              .take(40)
              .toList();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                key: const Key('area_search'),
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l10n.areaSearchHint,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: q.isNotEmpty && matches.isEmpty
                  ? Center(
                      key: const Key('area_empty'),
                      child: Text(l10n.areaNoResults),
                    )
                  : ListView(
                      children: [
                        for (final s in matches)
                          ListTile(
                            key: Key('area_tile_${s.id}'),
                            leading: const Icon(Icons.storefront_outlined),
                            title: Text(s.name),
                            subtitle: Text(s.address),
                            onTap: () => Navigator.of(context).pop(s),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:rocis_recipes/features/recipes/appliance.dart';
import 'package:rocis_recipes/l10n/app_localizations.dart';

String applianceLabel(AppLocalizations l10n, Appliance appliance) => switch (appliance) {
      Appliance.stovetop => l10n.applianceStovetop,
      Appliance.oven => l10n.applianceOven,
      Appliance.microwave => l10n.applianceMicrowave,
      Appliance.airFryer => l10n.applianceAirFryer,
      Appliance.blender => l10n.applianceBlender,
      Appliance.kettle => l10n.applianceKettle,
      Appliance.toaster => l10n.applianceToaster,
      Appliance.riceCooker => l10n.applianceRiceCooker,
    };

class AppliancePicker extends StatelessWidget {
  const AppliancePicker({super.key, required this.selected, required this.onChanged});

  final Set<Appliance> selected;
  final ValueChanged<Set<Appliance>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in Appliance.values)
          FilterChip(
            key: Key('appliance_${a.name}'),
            label: Text(applianceLabel(l10n, a)),
            selected: selected.contains(a),
            onSelected: (on) => onChanged(on ? {...selected, a} : ({...selected}..remove(a))),
          ),
      ],
    );
  }
}

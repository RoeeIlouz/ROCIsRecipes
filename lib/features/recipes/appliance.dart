enum Appliance { stovetop, oven, microwave, airFryer, blender, kettle, toaster, riceCooker }

Appliance? applianceFromName(String name) {
  for (final a in Appliance.values) {
    if (a.name == name) return a;
  }
  return null;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rocis_recipes/core/text/hebrew_normalizer.dart';

void main() {
  test('strips niqqud and final letters', () {
    expect(normalizeText('  עַגְבָנִיּוֹת  '), 'עגבניות');
    expect(normalizeText('לחם '), 'לחמ');
  });

  test('ignores quotes, punctuation and case', () {
    expect(normalizeText('Olive  OIL'), 'olive oil');
    expect(normalizeText("ג'ינג'ר"), 'גינגר');
    expect(normalizeText('תפו"א'), 'תפוא');
  });

  test('treats hyphens as spaces', () {
    expect(normalizeText('פלפל-שחור'), 'פלפל שחור');
  });
}

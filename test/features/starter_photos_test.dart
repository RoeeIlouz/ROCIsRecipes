import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the bundled starter pack: every credited photo exists, and credits are complete.
void main() {
  test(
    'every photo in the starter pack exists and carries author, license and source',
    () {
      final list =
          jsonDecode(File('assets/recipes/starter_he.json').readAsStringSync())
              as List;
      var withPhoto = 0;
      for (final r in list.cast<Map<String, dynamic>>()) {
        final photo = r['photo'] as Map<String, dynamic>?;
        if (photo == null) continue;
        withPhoto++;
        expect(
          File(photo['asset'] as String).existsSync(),
          isTrue,
          reason: '${r['id']} photo file',
        );
        expect(
          (photo['author'] as String).trim(),
          isNotEmpty,
          reason: '${r['id']} author',
        );
        expect(
          (photo['license'] as String).trim(),
          isNotEmpty,
          reason: '${r['id']} license',
        );
        expect(
          photo['sourceUrl'] as String,
          startsWith('https://commons.wikimedia.org/'),
          reason: '${r['id']} source',
        );
      }
      expect(withPhoto, greaterThan(list.length * 0.6));
    },
  );
}

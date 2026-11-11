import 'dart:convert';

import 'package:http/http.dart' as http;

/// Where the text of a recipe web page comes from (replaced by a fake in tests).
abstract class WebPageSource {
  /// The page at [uri] as text, or null when it cannot be loaded.
  Future<String?> fetch(Uri uri);
}

/// Loads a page over HTTP. Only the address the user pasted is requested; nothing else is sent.
class HttpWebPageSource implements WebPageSource {
  static const _maxBytes = 4 * 1024 * 1024;

  @override
  Future<String?> fetch(Uri uri) async {
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    try {
      final response = await http
          .get(
            uri,
            headers: const {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 14) ROCIsRecipes',
              'Accept-Language': 'he,en;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 || response.bodyBytes.length > _maxBytes) {
        return null;
      }
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }
}

/// A web address as a person types it: "example.com/x" gets https in front.
Uri? parseRecipeLink(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  final withScheme = text.contains('://') ? text : 'https://$text';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) return null;
  return uri;
}

final _scriptPattern = RegExp(
  r'''<script[^>]*type=["']application/ld\+json["'][^>]*>(.*?)</script>''',
  caseSensitive: false,
  dotAll: true,
);

/// The recipe of a page, in the same shape the on-device AI produces ({title, servings, minutes,
/// ingredients, steps}), read from the schema.org markup most recipe sites publish. Null when the page
/// has no recipe.
Map<String, dynamic>? recipeJsonFromHtml(String html) {
  for (final m in _scriptPattern.allMatches(html)) {
    final Object? data;
    try {
      data = jsonDecode(m.group(1)!.trim());
    } catch (_) {
      continue;
    }
    final node = _findRecipe(data);
    if (node == null) continue;
    final title = _text(node['name']);
    final ingredients = [
      for (final i in _list(node['recipeIngredient']))
        if (i is String && _text(i).isNotEmpty) _text(i),
    ];
    final steps = <String>[];
    _collectSteps(node['recipeInstructions'], steps);
    if (title.isEmpty || ingredients.isEmpty || steps.isEmpty) continue;
    final minutes =
        minutesFromIsoDuration(node['totalTime'] as String?) ??
        _sumMinutes(node['prepTime'], node['cookTime']);
    final servings = _firstInt(node['recipeYield']);
    return {
      'title': title,
      'servings': ?servings,
      'minutes': ?minutes,
      'ingredients': ingredients,
      'steps': steps,
    };
  }
  return null;
}

Map? _findRecipe(Object? data) {
  if (data is List) {
    for (final item in data) {
      final found = _findRecipe(item);
      if (found != null) return found;
    }
    return null;
  }
  if (data is! Map) return null;
  final type = data['@type'];
  if (type == 'Recipe' || (type is List && type.contains('Recipe'))) {
    return data;
  }
  return _findRecipe(data['@graph']);
}

List _list(Object? v) => v is List ? v : (v == null ? const [] : [v]);

void _collectSteps(Object? v, List<String> out) {
  if (v is String) {
    for (final line in v.split(RegExp(r'[\r\n]+'))) {
      final t = _text(line);
      if (t.isNotEmpty) out.add(t);
    }
  } else if (v is List) {
    for (final item in v) {
      _collectSteps(item, out);
    }
  } else if (v is Map) {
    if (v['itemListElement'] != null) {
      _collectSteps(v['itemListElement'], out);
    } else {
      _collectSteps(v['text'] ?? v['name'], out);
    }
  }
}

int? _firstInt(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) {
    final m = RegExp(r'\d+').firstMatch(v);
    return m == null ? null : int.parse(m.group(0)!);
  }
  if (v is List) {
    for (final item in v) {
      final found = _firstInt(item);
      if (found != null) return found;
    }
  }
  return null;
}

int? _sumMinutes(Object? a, Object? b) {
  final x = minutesFromIsoDuration(a is String ? a : null);
  final y = minutesFromIsoDuration(b is String ? b : null);
  if (x == null && y == null) return null;
  return (x ?? 0) + (y ?? 0);
}

/// "PT1H15M" is 75. Null for anything that is not an ISO 8601 duration.
int? minutesFromIsoDuration(String? iso) {
  if (iso == null) return null;
  final m = RegExp(
    r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:\d+S)?)?$',
  ).firstMatch(iso.trim());
  if (m == null) return null;
  final days = int.tryParse(m.group(1) ?? '') ?? 0;
  final hours = int.tryParse(m.group(2) ?? '') ?? 0;
  final minutes = int.tryParse(m.group(3) ?? '') ?? 0;
  final total = days * 1440 + hours * 60 + minutes;
  return total > 0 ? total : null;
}

String _text(Object? v) {
  if (v is! String) return '';
  var s = v
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ');
  s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m.group(1)!);
    return code == null ? '' : String.fromCharCode(code);
  });
  return s.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
}

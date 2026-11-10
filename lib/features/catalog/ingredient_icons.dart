/// Ingredient categories, in display order. Stored as `category` in assets/data/ingredients.json.
const List<String> kIngredientCategories = ['produce', 'dairy', 'meat', 'grains', 'pantry', 'spices', 'snacks'];

/// Generic icon per category, used when an ingredient has no icon of its own.
const Map<String, String> kCategoryEmoji = {
  'produce': '🥬',
  'dairy': '🧀',
  'meat': '🥩',
  'grains': '🌾',
  'pantry': '🥫',
  'spices': '🌿',
  'snacks': '🥜',
};

const String _genericEmoji = '🍽️';

// Emoji are drawn by the phone's own emoji font, so they cost no assets. Only emoji
// from Unicode 12 or earlier are used so they render on older Android versions too.
const Map<String, String> _emoji = {
  // produce
  'tomato': '🍅', 'cucumber': '🥒', 'onion': '🧅', 'garlic': '🧄', 'potato': '🥔', 'sweet_potato': '🍠',
  'carrot': '🥕', 'bell_pepper': '🌶️', 'chili': '🌶️', 'zucchini': '🥒', 'eggplant': '🍆', 'cabbage': '🥬',
  'lettuce': '🥬', 'spinach': '🥬', 'broccoli': '🥦', 'cauliflower': '🥦', 'mushroom': '🍄', 'corn': '🌽',
  'avocado': '🥑', 'lemon': '🍋', 'lime': '🍋', 'apple': '🍎', 'banana': '🍌', 'orange': '🍊',
  'parsley': '🌿', 'cilantro': '🌿', 'dill': '🌿', 'mint': '🌿', 'basil': '🌿', 'green_onion': '🌱',
  'ginger': '🌱', 'pumpkin': '🎃', 'beet': '🌱', 'celery': '🥬', 'peas': '🟢', 'green_beans': '🌱',
  // dairy and eggs
  'egg': '🥚', 'milk': '🥛', 'butter': '🧈', 'yogurt': '🥣', 'sour_cream': '🥣', 'cream': '🥛',
  'white_cheese': '🧀', 'cottage': '🧀', 'yellow_cheese': '🧀', 'mozzarella': '🧀', 'feta': '🧀',
  'parmesan': '🧀', 'labneh': '🥣', 'cream_cheese': '🧀',
  // meat and fish
  'chicken_breast': '🍗', 'chicken': '🍗', 'ground_beef': '🥩', 'beef': '🥩', 'schnitzel': '🍗',
  'sausage': '🌭', 'salmon': '🐟', 'tuna': '🐟', 'tofu': '🥡',
  // grains and legumes
  'rice': '🍚', 'pasta': '🍝', 'bread': '🍞', 'pita': '🥙', 'tortilla': '🌮', 'flour': '🌾', 'couscous': '🍚',
  'oats': '🌾', 'bulgur': '🌾', 'noodles': '🍜', 'breadcrumbs': '🍞', 'semolina': '🌾', 'quinoa': '🌾',
  'chickpeas': '🟡', 'lentils': '🟤', 'black_beans': '⚫', 'white_beans': '⚪', 'canned_corn': '🌽',
  // pantry
  'sugar': '🍬', 'brown_sugar': '🍬', 'honey': '🍯', 'vinegar': '🍶', 'soy_sauce': '🍶', 'ketchup': '🍅',
  'mayonnaise': '🥫', 'mustard': '🥫', 'olive_oil': '🍶', 'oil': '🍶', 'baking_powder': '🧁',
  'baking_soda': '🧂', 'vanilla': '🍦', 'cocoa': '🍫', 'chocolate': '🍫', 'peanut_butter': '🥜', 'jam': '🍓',
  'pesto': '🌿', 'coconut_milk': '🥥', 'tomato_paste': '🥫', 'canned_tomatoes': '🥫', 'tahini': '🥣',
  'salt': '🧂', 'pepper': '🧂', 'water': '💧', 'stock_powder': '🍲', 'frozen_vegetables': '🧊',
  // spices
  'cumin': '🌶️', 'paprika': '🌶️', 'turmeric': '🌶️', 'cinnamon': '🌶️', 'oregano': '🌿', 'thyme': '🌿',
  'garlic_powder': '🧄', 'onion_powder': '🧅', 'curry': '🌶️', 'chili_flakes': '🌶️', 'zaatar': '🌿',
  'cardamom': '🌶️', 'nutmeg': '🌰', 'bay_leaf': '🌿', 'sumac': '🌶️', 'hawaij': '🌶️',
  // nuts, drinks and more
  'almonds': '🌰', 'walnuts': '🌰', 'peanuts': '🥜', 'sesame': '🌱', 'sunflower_seeds': '🌻',
  'raisins': '🍇', 'olives': '🟢', 'pickles': '🥒', 'coffee': '☕', 'tea': '🍵',
};

/// Icon for an ingredient: its own, else its category's, else a generic plate.
String ingredientEmoji(String id, String? category) =>
    _emoji[id] ?? kCategoryEmoji[category] ?? _genericEmoji;

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ROCIs Recipes';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark (Slate)';

  @override
  String get amoledTheme => 'AMOLED (Pure Black)';

  @override
  String get glassmorphism => 'Glassmorphism';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get offlineMode => 'Offline Mode Active';

  @override
  String get pantryTitle => 'My kitchen';

  @override
  String get pantryInputHint => 'Type an ingredient';

  @override
  String get addIngredient => 'Add';

  @override
  String get pickFromList => 'Pick from list';

  @override
  String get pantryEmpty => 'Nothing here yet. Add what you have at home.';

  @override
  String get myIngredients => 'What I have';

  @override
  String get appliancesTitle => 'My appliances';

  @override
  String get cookingTimeTitle => 'Time I have';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get applianceStovetop => 'Stovetop';

  @override
  String get applianceOven => 'Oven';

  @override
  String get applianceMicrowave => 'Microwave';

  @override
  String get applianceAirFryer => 'Air fryer';

  @override
  String get applianceBlender => 'Blender';

  @override
  String get applianceKettle => 'Kettle';

  @override
  String get applianceToaster => 'Toaster';

  @override
  String get applianceRiceCooker => 'Rice cooker';

  @override
  String get tabCookNow => 'Cook now';

  @override
  String get tabAlmostThere => 'Almost there';

  @override
  String missingCount(int count) {
    return 'Missing $count';
  }

  @override
  String get noMatches =>
      'No dishes match yet. Add ingredients, appliances or more time.';

  @override
  String get ingredientsTitle => 'Ingredients';

  @override
  String get stepsTitle => 'Steps';

  @override
  String get missingBadge => 'Missing';

  @override
  String get addMissingToList => 'Add missing to shopping list';

  @override
  String get addedToList => 'Added to shopping list';

  @override
  String get startCooking => 'Start cooking';

  @override
  String stepOfTotal(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get nextStep => 'Next';

  @override
  String get previousStep => 'Back';

  @override
  String get finishCooking => 'Done';

  @override
  String get startTimer => 'Start timer';

  @override
  String get pauseTimer => 'Pause';

  @override
  String get navPantry => 'Kitchen';

  @override
  String get navSuggestions => 'Dishes';

  @override
  String get navShopping => 'Shopping';

  @override
  String get shoppingTitle => 'Shopping list';

  @override
  String get shoppingInputHint => 'Add an item';

  @override
  String get doneSection => 'In the cart';

  @override
  String get clearChecked => 'Clear checked';

  @override
  String get shoppingEmpty => 'Your list is empty.';

  @override
  String get timerDone => 'Time\'s up!';

  @override
  String get pricesTitle => 'Estimated prices';

  @override
  String get useMyLocation => 'Use my location to find the nearest branch';

  @override
  String get pickBranch => 'Choose a branch';

  @override
  String get estimateLabel => 'estimate';

  @override
  String partialTotal(int count) {
    return '$count items have no price';
  }

  @override
  String get noPriceData => 'No price data for your list';

  @override
  String tooFar(int km) {
    return 'No branch within $km km';
  }

  @override
  String distanceKm(String km) {
    return '$km km away';
  }

  @override
  String get navigate => 'Navigate';

  @override
  String staleWarning(String date) {
    return 'Prices may be out of date (last updated $date)';
  }

  @override
  String get osmAttribution => 'Map data from OpenStreetMap contributors';

  @override
  String get locationUnavailable =>
      'Location is not available, choose a branch yourself';

  @override
  String itemEstimate(String price) {
    return 'about $price';
  }

  @override
  String get pickerTitle => 'Choose ingredients';

  @override
  String get pickerSearchHint => 'Search ingredients';

  @override
  String get pickerDone => 'Done';

  @override
  String get pickerEmpty => 'No ingredients found';

  @override
  String get closeLabel => 'Close';

  @override
  String get categoryAll => 'All';

  @override
  String get catProduce => 'Fruit & veg';

  @override
  String get catDairy => 'Dairy & eggs';

  @override
  String get catMeat => 'Meat & fish';

  @override
  String get catGrains => 'Grains & legumes';

  @override
  String get catPantry => 'Pantry';

  @override
  String get catSpices => 'Spices';

  @override
  String get catSnacks => 'Nuts & drinks';

  @override
  String get mealAll => 'All meals';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack => 'Snack';

  @override
  String get mealDessert => 'Dessert';

  @override
  String get diffEasy => 'Easy';

  @override
  String get diffMedium => 'Medium';

  @override
  String servingsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servings',
      one: '1 serving',
    );
    return '$_temp0';
  }

  @override
  String photoCredit(String author, String license) {
    return 'Photo: $author, $license';
  }

  @override
  String get creditsTitle => 'Photo credits';

  @override
  String get creditsIntro =>
      'Recipe photos come from Wikimedia Commons under free licenses. Tap a photo to open its page.';

  @override
  String get creditsEmpty => 'No photo credits yet.';

  @override
  String get unitUnit => 'pcs';

  @override
  String get unitG => 'g';

  @override
  String get unitKg => 'kg';

  @override
  String get unitMl => 'ml';

  @override
  String get unitL => 'l';

  @override
  String unitTbsp(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tbsp',
      one: 'tbsp',
    );
    return '$_temp0';
  }

  @override
  String unitTsp(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tsp',
      one: 'tsp',
    );
    return '$_temp0';
  }

  @override
  String unitCup(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cups',
      one: 'cup',
    );
    return '$_temp0';
  }

  @override
  String unitClove(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cloves',
      one: 'clove',
    );
    return '$_temp0';
  }

  @override
  String unitBunch(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'bunches',
      one: 'bunch',
    );
    return '$_temp0';
  }

  @override
  String unitCan(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'cans',
      one: 'can',
    );
    return '$_temp0';
  }

  @override
  String unitPack(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'packs',
      one: 'pack',
    );
    return '$_temp0';
  }

  @override
  String unitSlice(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'slices',
      one: 'slice',
    );
    return '$_temp0';
  }

  @override
  String get unitPinch => 'pinch';

  @override
  String get recipeMissingTitle => 'Missing';

  @override
  String get optionalLabel => 'optional';

  @override
  String get chooseArea => 'Or choose an area by city or street';

  @override
  String get areaSearchHint => 'City, street or branch name';

  @override
  String get areaNoResults => 'No branch found there';

  @override
  String usingArea(String label) {
    return 'Area: $label';
  }

  @override
  String get edNew => 'New recipe';

  @override
  String get edEdit => 'Edit recipe';

  @override
  String get edName => 'Recipe name';

  @override
  String get edMinutes => 'Minutes';

  @override
  String get edServings => 'Servings';

  @override
  String get edIngredients => 'Ingredients';

  @override
  String get edAddIngredient => 'Search and add an ingredient';

  @override
  String get edQuantity => 'Qty';

  @override
  String get edUnit => 'Unit';

  @override
  String get edNoUnit => 'No unit';

  @override
  String get edSteps => 'Steps';

  @override
  String get edAddStep => 'Add a step';

  @override
  String get edStepHint => 'Describe the step';

  @override
  String get edPhotoGallery => 'From gallery';

  @override
  String get edPhotoCamera => 'Take a photo';

  @override
  String get edPhotoRemove => 'Remove photo';

  @override
  String get edSave => 'Save recipe';

  @override
  String get edNeedTitle => 'Give the recipe a name';

  @override
  String get edNeedIngredient => 'Add at least one ingredient';

  @override
  String get edNeedStep => 'Add at least one step';

  @override
  String get edDelete => 'Delete recipe';

  @override
  String get edDeleteConfirm => 'Delete this recipe for good?';

  @override
  String get myRecipe => 'My recipe';

  @override
  String get edSaved => 'Recipe saved';

  @override
  String get sendToTasks => 'Send to ROCIs Tasks';

  @override
  String get tasksNotInstalled => 'ROCIs Tasks is not installed';

  @override
  String get aiImportTitle => 'Import a recipe with AI';

  @override
  String get aiImportHint => 'Paste a recipe here, or add a photo of one';

  @override
  String get aiAnalyze => 'Read the recipe';

  @override
  String get aiPhotoAttached => 'Photo added';

  @override
  String get aiOnDeviceNote =>
      'The AI runs on your phone. Your text and photos never leave it.';

  @override
  String get aiDownloadTitle => 'Download the AI model?';

  @override
  String aiDownloadBody(String size) {
    return 'The AI model runs on your phone and needs a one-time download of about $size GB. Wi-Fi is recommended.';
  }

  @override
  String get aiDownload => 'Download';

  @override
  String get aiDownloading => 'Downloading the AI model';

  @override
  String get aiFailed =>
      'Could not read that. Try clearer text or a sharper photo.';

  @override
  String get aiScanTitle => 'Find ingredients in a photo';

  @override
  String get aiFoundTitle => 'Found these. Untick anything wrong.';

  @override
  String get aiFoundAdd => 'Add to my kitchen';

  @override
  String get aiNothingFound => 'No ingredients recognised in that photo';

  @override
  String get aiImportButton => 'Import with AI';

  @override
  String get aiScanButton => 'Scan a photo';
}

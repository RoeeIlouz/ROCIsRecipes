import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ROCIs Recipes'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark (Slate)'**
  String get darkTheme;

  /// No description provided for @amoledTheme.
  ///
  /// In en, this message translates to:
  /// **'AMOLED (Pure Black)'**
  String get amoledTheme;

  /// No description provided for @glassmorphism.
  ///
  /// In en, this message translates to:
  /// **'Glassmorphism'**
  String get glassmorphism;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode Active'**
  String get offlineMode;

  /// No description provided for @pantryTitle.
  ///
  /// In en, this message translates to:
  /// **'My kitchen'**
  String get pantryTitle;

  /// No description provided for @pantryInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type an ingredient'**
  String get pantryInputHint;

  /// No description provided for @addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addIngredient;

  /// No description provided for @pickFromList.
  ///
  /// In en, this message translates to:
  /// **'Pick from list'**
  String get pickFromList;

  /// No description provided for @pantryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Add what you have at home.'**
  String get pantryEmpty;

  /// No description provided for @myIngredients.
  ///
  /// In en, this message translates to:
  /// **'What I have'**
  String get myIngredients;

  /// No description provided for @appliancesTitle.
  ///
  /// In en, this message translates to:
  /// **'My appliances'**
  String get appliancesTitle;

  /// No description provided for @cookingTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time I have'**
  String get cookingTimeTitle;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @applianceStovetop.
  ///
  /// In en, this message translates to:
  /// **'Stovetop'**
  String get applianceStovetop;

  /// No description provided for @applianceOven.
  ///
  /// In en, this message translates to:
  /// **'Oven'**
  String get applianceOven;

  /// No description provided for @applianceMicrowave.
  ///
  /// In en, this message translates to:
  /// **'Microwave'**
  String get applianceMicrowave;

  /// No description provided for @applianceAirFryer.
  ///
  /// In en, this message translates to:
  /// **'Air fryer'**
  String get applianceAirFryer;

  /// No description provided for @applianceBlender.
  ///
  /// In en, this message translates to:
  /// **'Blender'**
  String get applianceBlender;

  /// No description provided for @applianceKettle.
  ///
  /// In en, this message translates to:
  /// **'Kettle'**
  String get applianceKettle;

  /// No description provided for @applianceToaster.
  ///
  /// In en, this message translates to:
  /// **'Toaster'**
  String get applianceToaster;

  /// No description provided for @applianceRiceCooker.
  ///
  /// In en, this message translates to:
  /// **'Rice cooker'**
  String get applianceRiceCooker;

  /// No description provided for @tabCookNow.
  ///
  /// In en, this message translates to:
  /// **'Cook now'**
  String get tabCookNow;

  /// No description provided for @tabAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there'**
  String get tabAlmostThere;

  /// No description provided for @missingCount.
  ///
  /// In en, this message translates to:
  /// **'Missing {count}'**
  String missingCount(int count);

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No dishes match yet. Add ingredients, appliances or more time.'**
  String get noMatches;

  /// No description provided for @ingredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsTitle;

  /// No description provided for @stepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsTitle;

  /// No description provided for @missingBadge.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missingBadge;

  /// No description provided for @addMissingToList.
  ///
  /// In en, this message translates to:
  /// **'Add missing to shopping list'**
  String get addMissingToList;

  /// No description provided for @addedToList.
  ///
  /// In en, this message translates to:
  /// **'Added to shopping list'**
  String get addedToList;

  /// No description provided for @startCooking.
  ///
  /// In en, this message translates to:
  /// **'Start cooking'**
  String get startCooking;

  /// No description provided for @stepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOfTotal(int current, int total);

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextStep;

  /// No description provided for @previousStep.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get previousStep;

  /// No description provided for @finishCooking.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get finishCooking;

  /// No description provided for @startTimer.
  ///
  /// In en, this message translates to:
  /// **'Start timer'**
  String get startTimer;

  /// No description provided for @pauseTimer.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseTimer;

  /// No description provided for @navPantry.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get navPantry;

  /// No description provided for @navSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Dishes'**
  String get navSuggestions;

  /// No description provided for @navShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get navShopping;

  /// No description provided for @shoppingTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get shoppingTitle;

  /// No description provided for @shoppingInputHint.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get shoppingInputHint;

  /// No description provided for @doneSection.
  ///
  /// In en, this message translates to:
  /// **'In the cart'**
  String get doneSection;

  /// No description provided for @clearChecked.
  ///
  /// In en, this message translates to:
  /// **'Clear checked'**
  String get clearChecked;

  /// No description provided for @shoppingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your list is empty.'**
  String get shoppingEmpty;

  /// No description provided for @timerDone.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up!'**
  String get timerDone;

  /// No description provided for @pricesTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated prices'**
  String get pricesTitle;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location to find the nearest branch'**
  String get useMyLocation;

  /// No description provided for @pickBranch.
  ///
  /// In en, this message translates to:
  /// **'Choose a branch'**
  String get pickBranch;

  /// No description provided for @estimateLabel.
  ///
  /// In en, this message translates to:
  /// **'estimate'**
  String get estimateLabel;

  /// No description provided for @partialTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} items have no price'**
  String partialTotal(int count);

  /// No description provided for @noPriceData.
  ///
  /// In en, this message translates to:
  /// **'No price data for your list'**
  String get noPriceData;

  /// No description provided for @tooFar.
  ///
  /// In en, this message translates to:
  /// **'No branch within {km} km'**
  String tooFar(int km);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String distanceKm(String km);

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @staleWarning.
  ///
  /// In en, this message translates to:
  /// **'Prices may be out of date (last updated {date})'**
  String staleWarning(String date);

  /// No description provided for @osmAttribution.
  ///
  /// In en, this message translates to:
  /// **'Map data from OpenStreetMap contributors'**
  String get osmAttribution;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location is not available, choose a branch yourself'**
  String get locationUnavailable;

  /// No description provided for @itemEstimate.
  ///
  /// In en, this message translates to:
  /// **'about {price}'**
  String itemEstimate(String price);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

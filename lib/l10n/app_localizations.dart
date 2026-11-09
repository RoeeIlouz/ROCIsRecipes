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

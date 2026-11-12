// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'ROCIs Recipes';

  @override
  String get settings => 'הגדרות';

  @override
  String get theme => 'ערכת נושא';

  @override
  String get lightTheme => 'בהיר';

  @override
  String get darkTheme => 'כהה (Slate)';

  @override
  String get amoledTheme => 'AMOLED (שחור מוחלט)';

  @override
  String get glassmorphism => 'אפקט זכוכית (Glassmorphism)';

  @override
  String get save => 'שמור';

  @override
  String get cancel => 'ביטול';

  @override
  String get delete => 'מחק';

  @override
  String get offlineMode => 'מצב לא מקוון פעיל';

  @override
  String get pantryTitle => 'המטבח שלי';

  @override
  String get pantryInputHint => 'הקלידו מצרך';

  @override
  String get addIngredient => 'הוסף';

  @override
  String get pickFromList => 'בחירה מרשימה';

  @override
  String get pantryEmpty => 'עדיין ריק. הוסיפו מה שיש לכם בבית.';

  @override
  String get myIngredients => 'מה יש לי';

  @override
  String get appliancesTitle => 'המכשירים שלי';

  @override
  String get cookingTimeTitle => 'כמה זמן יש לי';

  @override
  String minutesShort(int count) {
    return '$count דק\'';
  }

  @override
  String get applianceStovetop => 'כיריים';

  @override
  String get applianceOven => 'תנור';

  @override
  String get applianceMicrowave => 'מיקרוגל';

  @override
  String get applianceAirFryer => 'איר פרייר';

  @override
  String get applianceBlender => 'בלנדר';

  @override
  String get applianceKettle => 'קומקום';

  @override
  String get applianceToaster => 'טוסטר';

  @override
  String get applianceRiceCooker => 'סיר אורז';

  @override
  String get tabCookNow => 'לבשל עכשיו';

  @override
  String get tabAlmostThere => 'כמעט שם';

  @override
  String missingCount(int count) {
    return 'חסרים $count';
  }

  @override
  String get noMatches =>
      'אין עדיין מנות מתאימות. הוסיפו מצרכים, מכשירים או יותר זמן.';

  @override
  String get ingredientsTitle => 'מצרכים';

  @override
  String get stepsTitle => 'שלבים';

  @override
  String get missingBadge => 'חסר';

  @override
  String get addMissingToList => 'הוסיפו את החסר לרשימת הקניות';

  @override
  String get addedToList => 'נוספו לרשימת הקניות';

  @override
  String get startCooking => 'התחילו לבשל';

  @override
  String stepOfTotal(int current, int total) {
    return 'שלב $current מתוך $total';
  }

  @override
  String get nextStep => 'הבא';

  @override
  String get previousStep => 'הקודם';

  @override
  String get finishCooking => 'סיימתי';

  @override
  String get startTimer => 'הפעל טיימר';

  @override
  String get pauseTimer => 'השהה';

  @override
  String get navPantry => 'מטבח';

  @override
  String get navSuggestions => 'מנות';

  @override
  String get navShopping => 'קניות';

  @override
  String get navPlan => 'תפריט';

  @override
  String get planTitle => 'תפריט שבועי';

  @override
  String get planIntro =>
      'בחרו סופרמרקט, קבעו תקציב ואנחנו נבנה שבוע של ארוחות שמתאים לו.';

  @override
  String get planBuild => 'בנו לי שבוע';

  @override
  String get planRebuild => 'בנייה מחדש';

  @override
  String get planAddToList => 'הוסיפו לרשימת הקניות';

  @override
  String get planAdded => 'מצרכי השבוע נוספו לרשימה';

  @override
  String get planTotal => 'לקנייה השבוע';

  @override
  String get planTonight => 'הערב';

  @override
  String get planCook => 'לבשל';

  @override
  String get planSwap => 'החלפת מנה';

  @override
  String get planSkip => 'דלגו על היום';

  @override
  String get planUnskip => 'החזירו את היום';

  @override
  String get planHide => 'אל תציעו שוב';

  @override
  String get planEmptyDay => 'אין מנה שמתאימה לתקציב';

  @override
  String get planSkippedDay => 'דילגתם';

  @override
  String get planSupermarket => 'סופרמרקט';

  @override
  String get planNoStore => 'בחרו מיקום או אזור כדי לתמחר את השבוע';

  @override
  String get shoppingTitle => 'רשימת קניות';

  @override
  String get shoppingInputHint => 'הוסיפו פריט';

  @override
  String get doneSection => 'בעגלה';

  @override
  String get clearChecked => 'נקה מסומנים';

  @override
  String get shoppingEmpty => 'הרשימה ריקה.';

  @override
  String get timerDone => 'הזמן נגמר!';

  @override
  String get pricesTitle => 'מחירים משוערים';

  @override
  String get useMyLocation => 'השתמשו במיקום שלי כדי למצוא את הסניף הקרוב';

  @override
  String get pickBranch => 'בחרו סניף';

  @override
  String get estimateLabel => 'הערכה';

  @override
  String partialTotal(int count) {
    return 'ל-$count פריטים אין מחיר';
  }

  @override
  String get noPriceData => 'אין נתוני מחיר לרשימה';

  @override
  String tooFar(int km) {
    return 'אין סניף ברדיוס $km ק\"מ';
  }

  @override
  String distanceKm(String km) {
    return 'במרחק $km ק\"מ';
  }

  @override
  String get navigate => 'ניווט';

  @override
  String staleWarning(String date) {
    return 'ייתכן שהמחירים לא עדכניים (עודכנו לאחרונה $date)';
  }

  @override
  String get osmAttribution => 'נתוני מפה מתורמי OpenStreetMap';

  @override
  String get locationUnavailable => 'המיקום לא זמין, בחרו סניף בעצמכם';

  @override
  String itemEstimate(String price) {
    return 'כ-$price';
  }

  @override
  String get pickerTitle => 'בחרו מצרכים';

  @override
  String get pickerSearchHint => 'חיפוש מצרכים';

  @override
  String get pickerDone => 'סיום';

  @override
  String get pickerEmpty => 'לא נמצאו מצרכים';

  @override
  String get closeLabel => 'סגירה';

  @override
  String get categoryAll => 'הכול';

  @override
  String get catProduce => 'ירקות ופירות';

  @override
  String get catDairy => 'חלב וביצים';

  @override
  String get catMeat => 'בשר ודגים';

  @override
  String get catGrains => 'דגנים וקטניות';

  @override
  String get catPantry => 'מזווה';

  @override
  String get catSpices => 'תבלינים';

  @override
  String get catSnacks => 'אגוזים ושתייה';

  @override
  String get mealAll => 'כל הארוחות';

  @override
  String get mealBreakfast => 'ארוחת בוקר';

  @override
  String get mealLunch => 'צהריים';

  @override
  String get mealDinner => 'ערב';

  @override
  String get mealSnack => 'נשנוש';

  @override
  String get mealDessert => 'קינוח';

  @override
  String get diffEasy => 'קל';

  @override
  String get diffMedium => 'בינוני';

  @override
  String servingsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מנות',
      one: 'מנה אחת',
    );
    return '$_temp0';
  }

  @override
  String photoCredit(String author, String license) {
    return 'צילום: $author, $license';
  }

  @override
  String get creditsTitle => 'קרדיטים לתמונות';

  @override
  String get creditsIntro =>
      'תמונות המתכונים מגיעות מ-Wikimedia Commons ברישיונות חופשיים. לחיצה על תמונה פותחת את עמוד המקור.';

  @override
  String get creditsEmpty => 'עדיין אין קרדיטים לתמונות.';

  @override
  String get unitUnit => 'יח\'';

  @override
  String get unitG => 'גרם';

  @override
  String get unitKg => 'ק\"ג';

  @override
  String get unitMl => 'מ\"ל';

  @override
  String get unitL => 'ליטר';

  @override
  String unitTbsp(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'כפות',
      one: 'כף',
    );
    return '$_temp0';
  }

  @override
  String unitTsp(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'כפיות',
      one: 'כפית',
    );
    return '$_temp0';
  }

  @override
  String unitCup(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'כוסות',
      one: 'כוס',
    );
    return '$_temp0';
  }

  @override
  String unitClove(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'שיניים',
      one: 'שן',
    );
    return '$_temp0';
  }

  @override
  String unitBunch(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'צרורות',
      one: 'צרור',
    );
    return '$_temp0';
  }

  @override
  String unitCan(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'קופסאות',
      one: 'קופסה',
    );
    return '$_temp0';
  }

  @override
  String unitPack(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'חבילות',
      one: 'חבילה',
    );
    return '$_temp0';
  }

  @override
  String unitSlice(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'פרוסות',
      one: 'פרוסה',
    );
    return '$_temp0';
  }

  @override
  String get unitPinch => 'קורט';

  @override
  String get recipeMissingTitle => 'חסר';

  @override
  String get optionalLabel => 'אופציונלי';

  @override
  String get chooseArea => 'או בחרו אזור לפי עיר או רחוב';

  @override
  String get areaSearchHint => 'עיר, רחוב או שם סניף';

  @override
  String get areaNoResults => 'לא נמצא סניף שם';

  @override
  String usingArea(String label) {
    return 'אזור: $label';
  }

  @override
  String get edNew => 'מתכון חדש';

  @override
  String get edEdit => 'עריכת מתכון';

  @override
  String get edName => 'שם המתכון';

  @override
  String get edMinutes => 'דקות';

  @override
  String get edServings => 'מנות';

  @override
  String get edIngredients => 'מצרכים';

  @override
  String get edAddIngredient => 'חפשו והוסיפו מצרך';

  @override
  String get edQuantity => 'כמות';

  @override
  String get edUnit => 'יחידה';

  @override
  String get edNoUnit => 'ללא יחידה';

  @override
  String get edSteps => 'שלבים';

  @override
  String get edAddStep => 'הוסיפו שלב';

  @override
  String get edStepHint => 'תארו את השלב';

  @override
  String get edPhotoGallery => 'מהגלריה';

  @override
  String get edPhotoCamera => 'צלמו תמונה';

  @override
  String get edPhotoRemove => 'הסירו תמונה';

  @override
  String get edSave => 'שמירת המתכון';

  @override
  String get edNeedTitle => 'תנו שם למתכון';

  @override
  String get edNeedIngredient => 'הוסיפו לפחות מצרך אחד';

  @override
  String get edNeedStep => 'הוסיפו לפחות שלב אחד';

  @override
  String get edDelete => 'מחיקת מתכון';

  @override
  String get edDeleteConfirm => 'למחוק את המתכון לצמיתות?';

  @override
  String get myRecipe => 'המתכון שלי';

  @override
  String get edSaved => 'המתכון נשמר';

  @override
  String get sendToTasks => 'שליחה ל-ROCIs Tasks';

  @override
  String get tasksNotInstalled => 'ROCIs Tasks לא מותקן';

  @override
  String get aiImportTitle => 'ייבוא מתכון עם AI';

  @override
  String get aiImportHint => 'הדביקו כאן מתכון, או הוסיפו תמונה של מתכון';

  @override
  String get aiAnalyze => 'קראו את המתכון';

  @override
  String get aiPhotoAttached => 'תמונה נוספה';

  @override
  String get aiOnDeviceNote =>
      'ה-AI רץ בטלפון שלכם. הטקסט והתמונות לא יוצאים ממנו.';

  @override
  String get aiDownloadTitle => 'להוריד את מודל ה-AI?';

  @override
  String aiDownloadBody(String size) {
    return 'מודל ה-AI רץ בטלפון ודורש הורדה חד פעמית של כ-$size ג\'יגה. מומלץ ב-Wi-Fi.';
  }

  @override
  String get aiDownload => 'הורדה';

  @override
  String get aiDownloading => 'מוריד את מודל ה-AI';

  @override
  String get aiFailed =>
      'לא הצלחתי לקרוא את זה. נסו טקסט ברור יותר או תמונה חדה.';

  @override
  String get aiScanTitle => 'זיהוי מצרכים מתמונה';

  @override
  String get aiFoundTitle => 'זיהיתי את אלה. בטלו סימון למה שלא נכון.';

  @override
  String get aiFoundAdd => 'הוספה למטבח שלי';

  @override
  String get aiNothingFound => 'לא זוהו מצרכים בתמונה הזו';

  @override
  String get aiImportButton => 'ייבוא עם AI';

  @override
  String get aiScanButton => 'סריקת תמונה';

  @override
  String get proteinAll => 'כל סוג';

  @override
  String get proteinChicken => 'עוף';

  @override
  String get proteinBeef => 'בקר ובשר';

  @override
  String get proteinFish => 'דגים';

  @override
  String get proteinVegetarian => 'ללא בשר';

  @override
  String get mealPrepChip => 'הכנה מראש';

  @override
  String get mealPrepLabel => 'הכנה מראש';

  @override
  String get favoritesChip => 'מועדפים';

  @override
  String get budgetTitle => 'תקציב שבועי';

  @override
  String get budgetSet => 'קבעו תקציב שבועי';

  @override
  String get budgetEdit => 'שינוי תקציב';

  @override
  String get budgetFieldLabel => 'תקציב שבועי לאוכל (בש״ח)';

  @override
  String get budgetSave => 'שמירה';

  @override
  String get budgetClear => 'ללא תקציב';

  @override
  String budgetUsed(String spent, String budget) {
    return '$spent מתוך $budget';
  }

  @override
  String budgetLeft(String amount) {
    return 'נשארו $amount';
  }

  @override
  String budgetOver(String amount) {
    return 'חריגה של $amount';
  }

  @override
  String get budgetChip => 'בתוך התקציב';

  @override
  String buyCost(String amount) {
    return 'כ-$amount לקנייה';
  }

  @override
  String get storesTitle => 'חנויות לידי';

  @override
  String get storesTooltip => 'מציאת חנויות';

  @override
  String get storesCheapest => 'הזול ביותר לרשימה';

  @override
  String get storesNoBranch => 'לא נמצא סניף בסביבה';

  @override
  String get storesNeedLocation =>
      'שתפו מיקום או בחרו אזור כדי לראות את החנויות הקרובות';

  @override
  String get linkImportButton => 'ייבוא מקישור';

  @override
  String get linkImportTitle => 'הדביקו קישור למתכון';

  @override
  String get linkImportAction => 'ייבוא';

  @override
  String get linkImportNoRecipe => 'לא נמצא מתכון בעמוד הזה. נסו קישור אחר.';

  @override
  String get linkImportFailed =>
      'לא הצלחתי לפתוח את העמוד. בדקו את הקישור ואת החיבור.';

  @override
  String get favoriteAdd => 'הוספה למועדפים';

  @override
  String get favoriteRemove => 'הסרה מהמועדפים';

  @override
  String get servingsLess => 'פחות מנות';

  @override
  String get servingsMore => 'יותר מנות';

  @override
  String get aiInventTooltip => 'המצאת מנה ממה שיש לי';

  @override
  String get aiNeedIngredients => 'הוסיפו קודם מצרכים למטבח';

  @override
  String get aiInventing => 'ממציא מנה...';

  @override
  String get aiDraftNote => 'טיוטה מה-AI: בדקו לפני הבישול';

  @override
  String aiErrorDetail(String detail) {
    return 'פרטים: $detail';
  }

  @override
  String get aiLoadingModel => 'טוען את ה-AI. בפעם הראשונה זה יכול לקחת כדקה.';

  @override
  String get aiTimedOut =>
      'ה-AI לקח יותר מדי זמן. סגרו אפליקציות אחרות ונסו שוב.';
}

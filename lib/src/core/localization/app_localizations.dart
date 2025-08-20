import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
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
    Locale('es'),
  ];

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'TeditoX'**
  String get app_name;

  /// No description provided for @new_file.
  ///
  /// In en, this message translates to:
  /// **'New File'**
  String get new_file;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @save_as.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get save_as;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @recent_files.
  ///
  /// In en, this message translates to:
  /// **'Recent Files'**
  String get recent_files;

  /// No description provided for @modified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get modified;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @encoding.
  ///
  /// In en, this message translates to:
  /// **'Encoding'**
  String get encoding;

  /// No description provided for @line_endings.
  ///
  /// In en, this message translates to:
  /// **'Line endings'**
  String get line_endings;

  /// No description provided for @wrap_lines.
  ///
  /// In en, this message translates to:
  /// **'Wrap lines'**
  String get wrap_lines;

  /// No description provided for @line_numbers.
  ///
  /// In en, this message translates to:
  /// **'Line numbers'**
  String get line_numbers;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @font_size.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get font_size;

  /// No description provided for @word_count.
  ///
  /// In en, this message translates to:
  /// **'Word/Char/Line count'**
  String get word_count;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clear_recent_files.
  ///
  /// In en, this message translates to:
  /// **'Clear Recent Files'**
  String get clear_recent_files;

  /// No description provided for @clear_recent_files_confirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all recent files? This action cannot be undone.'**
  String get clear_recent_files_confirmation;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @unsaved_recovery_found.
  ///
  /// In en, this message translates to:
  /// **'Unsaved recovery found'**
  String get unsaved_recovery_found;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @unsaved_changes.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsaved_changes;

  /// No description provided for @unsaved_changes_message.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Save before leaving?'**
  String get unsaved_changes_message;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @last_opened.
  ///
  /// In en, this message translates to:
  /// **'Last opened'**
  String get last_opened;

  /// No description provided for @last_modified.
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get last_modified;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @editor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get editor;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @undo_depth.
  ///
  /// In en, this message translates to:
  /// **'Undo depth'**
  String get undo_depth;

  /// No description provided for @max_file_size.
  ///
  /// In en, this message translates to:
  /// **'Max file size'**
  String get max_file_size;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @more_actions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get more_actions;

  /// No description provided for @file_operations.
  ///
  /// In en, this message translates to:
  /// **'File Operations'**
  String get file_operations;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// No description provided for @view_license.
  ///
  /// In en, this message translates to:
  /// **'View License'**
  String get view_license;

  /// No description provided for @view_privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'View Privacy Policy'**
  String get view_privacy_policy;

  /// No description provided for @app_description.
  ///
  /// In en, this message translates to:
  /// **'Simple plain text editor'**
  String get app_description;

  /// No description provided for @could_not_launch_url.
  ///
  /// In en, this message translates to:
  /// **'Could not launch {url}'**
  String could_not_launch_url(String url);
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

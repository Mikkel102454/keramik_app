import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_en.dart';

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
    Locale('da'),
    Locale('en'),
  ];

  /// The native name of this language, shown in the language selector.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Keramik'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWait;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessages;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String errorWithDetails(String details);

  /// No description provided for @stageIdeas.
  ///
  /// In en, this message translates to:
  /// **'Ideas'**
  String get stageIdeas;

  /// No description provided for @stageThrown.
  ///
  /// In en, this message translates to:
  /// **'Thrown'**
  String get stageThrown;

  /// No description provided for @stageTrimmed.
  ///
  /// In en, this message translates to:
  /// **'Trimmed'**
  String get stageTrimmed;

  /// No description provided for @stageBisqued.
  ///
  /// In en, this message translates to:
  /// **'Bisqued'**
  String get stageBisqued;

  /// No description provided for @stageGlazed.
  ///
  /// In en, this message translates to:
  /// **'Glazed'**
  String get stageGlazed;

  /// No description provided for @stageFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get stageFinished;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @measurementMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get measurementMetric;

  /// No description provided for @measurementImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get measurementImperial;

  /// No description provided for @privacyEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get privacyEveryone;

  /// No description provided for @privacyFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get privacyFriends;

  /// No description provided for @privacyFriendsOfFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends of friends'**
  String get privacyFriendsOfFriends;

  /// No description provided for @privacyNoOne.
  ///
  /// In en, this message translates to:
  /// **'No one'**
  String get privacyNoOne;

  /// No description provided for @settingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be loaded. Check your connection and retry.'**
  String get settingsLoadFailed;

  /// No description provided for @settingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'That setting could not be saved. Your previous choice was restored.'**
  String get settingSaveFailed;

  /// No description provided for @settingsAndPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Settings and privacy'**
  String get settingsAndPrivacy;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account information'**
  String get accountInformation;

  /// No description provided for @passwordAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Password and security'**
  String get passwordAndSecurity;

  /// No description provided for @downloadYourData.
  ///
  /// In en, this message translates to:
  /// **'Download your data'**
  String get downloadYourData;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @discoverability.
  ///
  /// In en, this message translates to:
  /// **'Discoverability'**
  String get discoverability;

  /// No description provided for @whoCanDiscover.
  ///
  /// In en, this message translates to:
  /// **'Who can discover your account?'**
  String get whoCanDiscover;

  /// No description provided for @friendRequests.
  ///
  /// In en, this message translates to:
  /// **'Friend requests'**
  String get friendRequests;

  /// No description provided for @whoCanSendFriendRequests.
  ///
  /// In en, this message translates to:
  /// **'Who can send friend requests?'**
  String get whoCanSendFriendRequests;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @whoCanSendMessageRequests.
  ///
  /// In en, this message translates to:
  /// **'Who can send message requests?'**
  String get whoCanSendMessageRequests;

  /// No description provided for @blockedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Blocked accounts'**
  String get blockedAccounts;

  /// No description provided for @contentAndDisplay.
  ///
  /// In en, this message translates to:
  /// **'Content and display'**
  String get contentAndDisplay;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @supportAndAbout.
  ///
  /// In en, this message translates to:
  /// **'Support and about'**
  String get supportAndAbout;

  /// No description provided for @websiteHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Website help center'**
  String get websiteHelpCenter;

  /// No description provided for @privacyInformation.
  ///
  /// In en, this message translates to:
  /// **'Privacy information'**
  String get privacyInformation;

  /// No description provided for @aboutKeramik.
  ///
  /// In en, this message translates to:
  /// **'About Keramik'**
  String get aboutKeramik;

  /// No description provided for @loginSection.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginSection;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out…'**
  String get loggingOut;

  /// No description provided for @logOutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutQuestion;

  /// No description provided for @logOutExplanation.
  ///
  /// In en, this message translates to:
  /// **'You can sign back in with your email or username.'**
  String get logOutExplanation;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed. Your session is still active; please retry.'**
  String get logoutFailed;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The link could not be opened.'**
  String get linkOpenFailed;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current language'**
  String get currentLanguage;

  /// No description provided for @languageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The language could not be saved. Your previous language was restored.'**
  String get languageSaveFailed;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @publicUserId.
  ///
  /// In en, this message translates to:
  /// **'Public user ID'**
  String get publicUserId;

  /// No description provided for @accountInformationPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your public user ID is used for profile links and cannot be changed.'**
  String get accountInformationPrivacyNote;

  /// No description provided for @accountInformationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Account information could not be loaded.'**
  String get accountInformationLoadFailed;

  /// No description provided for @accountEmailPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your email address is private. For security, account email changes are handled through support.'**
  String get accountEmailPrivacyNote;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @passwordLengthHelp.
  ///
  /// In en, this message translates to:
  /// **'Use 8–128 characters.'**
  String get passwordLengthHelp;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @websitePasswordPage.
  ///
  /// In en, this message translates to:
  /// **'Use the website password page'**
  String get websitePasswordPage;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'The new passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Other sessions have been signed out.'**
  String get passwordChanged;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Password could not be changed. Please retry.'**
  String get passwordChangeFailed;

  /// No description provided for @dataExportDescription.
  ///
  /// In en, this message translates to:
  /// **'Your ZIP includes JSON/CSV records, preferences, relationships, accessible conversation data, and server-stored profile, ceramic, and clay images.'**
  String get dataExportDescription;

  /// No description provided for @dataExportLimit.
  ///
  /// In en, this message translates to:
  /// **'Only one export can run at a time. Completed packages expire after seven days.'**
  String get dataExportLimit;

  /// No description provided for @exportRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'The export could not be requested.'**
  String get exportRequestFailed;

  /// No description provided for @exportRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Export status could not be refreshed.'**
  String get exportRefreshFailed;

  /// No description provided for @exportDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The ZIP could not be downloaded or opened.'**
  String get exportDownloadFailed;

  /// No description provided for @availableUntil.
  ///
  /// In en, this message translates to:
  /// **'Available until {date}'**
  String availableUntil(String date);

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @downloadZip.
  ///
  /// In en, this message translates to:
  /// **'Download ZIP'**
  String get downloadZip;

  /// No description provided for @createExport.
  ///
  /// In en, this message translates to:
  /// **'Create export'**
  String get createExport;

  /// No description provided for @exportQueued.
  ///
  /// In en, this message translates to:
  /// **'Export queued'**
  String get exportQueued;

  /// No description provided for @exportCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating your export'**
  String get exportCreating;

  /// No description provided for @exportReady.
  ///
  /// In en, this message translates to:
  /// **'Export ready'**
  String get exportReady;

  /// No description provided for @exportExpired.
  ///
  /// In en, this message translates to:
  /// **'Export expired'**
  String get exportExpired;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @deletionScheduleFailed.
  ///
  /// In en, this message translates to:
  /// **'Deletion could not be scheduled. Please retry.'**
  String get deletionScheduleFailed;

  /// No description provided for @deletionCancellationPeriod.
  ///
  /// In en, this message translates to:
  /// **'Deletion starts a 30-day cancellation period.'**
  String get deletionCancellationPeriod;

  /// No description provided for @deletionSignOutExplanation.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out everywhere immediately and cannot use ordinary app features. Sign in again during the next 30 days to cancel deletion or sign out.'**
  String get deletionSignOutExplanation;

  /// No description provided for @deletionRetentionExplanation.
  ///
  /// In en, this message translates to:
  /// **'After 30 days, private identity, journal and material data, and owned media are erased. A disabled pseudonymous account shell and shared chat, report, audit, and safety records are retained indefinitely. Other members will see “Deleted member.”'**
  String get deletionRetentionExplanation;

  /// No description provided for @deletionUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand what is erased and retained.'**
  String get deletionUnderstand;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get typeDeleteToConfirm;

  /// No description provided for @scheduleAccountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Schedule account deletion'**
  String get scheduleAccountDeletion;

  /// No description provided for @directMessages.
  ///
  /// In en, this message translates to:
  /// **'Direct messages'**
  String get directMessages;

  /// No description provided for @messageRequests.
  ///
  /// In en, this message translates to:
  /// **'Message requests'**
  String get messageRequests;

  /// No description provided for @groupActivity.
  ///
  /// In en, this message translates to:
  /// **'Group activity'**
  String get groupActivity;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsComingLater.
  ///
  /// In en, this message translates to:
  /// **'Coming later. Keramik does not deliver notifications while the app is suspended.'**
  String get pushNotificationsComingLater;

  /// No description provided for @blockedAccountsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Blocked accounts could not be loaded.'**
  String get blockedAccountsLoadFailed;

  /// No description provided for @accountUnblockFailed.
  ///
  /// In en, this message translates to:
  /// **'{username} could not be unblocked.'**
  String accountUnblockFailed(String username);

  /// No description provided for @noBlockedAccounts.
  ///
  /// In en, this message translates to:
  /// **'You have not blocked any accounts.'**
  String get noBlockedAccounts;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToAccount;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get emailOrUsername;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @accountDeletionPending.
  ///
  /// In en, this message translates to:
  /// **'Account deletion pending'**
  String get accountDeletionPending;

  /// No description provided for @accountDeletionPendingExplanation.
  ///
  /// In en, this message translates to:
  /// **'Ordinary activity is restricted during the 30-day grace period. Cancel deletion to restore the account, or sign out.'**
  String get accountDeletionPendingExplanation;

  /// No description provided for @cancelDeletion.
  ///
  /// In en, this message translates to:
  /// **'Cancel deletion'**
  String get cancelDeletion;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @noAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account? '**
  String get noAccountQuestion;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @materials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materials;

  /// No description provided for @clays.
  ///
  /// In en, this message translates to:
  /// **'Clays'**
  String get clays;

  /// No description provided for @glazes.
  ///
  /// In en, this message translates to:
  /// **'Glazes'**
  String get glazes;

  /// No description provided for @navigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navigationHome;

  /// No description provided for @navigationMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get navigationMaterials;

  /// No description provided for @navigationShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navigationShop;

  /// No description provided for @navigationChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navigationChats;

  /// No description provided for @navigationProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navigationProfile;

  /// No description provided for @ceramicJournal.
  ///
  /// In en, this message translates to:
  /// **'Ceramic journal'**
  String get ceramicJournal;

  /// No description provided for @journalLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not load your ceramic journal.'**
  String get journalLoadFailed;

  /// No description provided for @createCeramic.
  ///
  /// In en, this message translates to:
  /// **'Create ceramic'**
  String get createCeramic;

  /// No description provided for @journalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles, notes, tags, clay, or glaze'**
  String get journalSearchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @pieceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No pieces} =1 {1 piece} other {{count} pieces}}'**
  String pieceCount(int count);

  /// No description provided for @unknownStage.
  ///
  /// In en, this message translates to:
  /// **'Unknown stage'**
  String get unknownStage;

  /// No description provided for @filterJournal.
  ///
  /// In en, this message translates to:
  /// **'Filter journal'**
  String get filterJournal;

  /// No description provided for @stage.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stage;

  /// No description provided for @clay.
  ///
  /// In en, this message translates to:
  /// **'Clay'**
  String get clay;

  /// No description provided for @glaze.
  ///
  /// In en, this message translates to:
  /// **'Glaze'**
  String get glaze;

  /// No description provided for @minimumRating.
  ///
  /// In en, this message translates to:
  /// **'Minimum rating'**
  String get minimumRating;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @sortRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get sortRecentlyUpdated;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @creationDate.
  ///
  /// In en, this message translates to:
  /// **'Creation date'**
  String get creationDate;

  /// No description provided for @startCeramicJournal.
  ///
  /// In en, this message translates to:
  /// **'Start your ceramic journal'**
  String get startCeramicJournal;

  /// No description provided for @emptyJournalDescription.
  ///
  /// In en, this message translates to:
  /// **'Capture your first piece, materials, process, and results.'**
  String get emptyJournalDescription;

  /// No description provided for @createFirstPiece.
  ///
  /// In en, this message translates to:
  /// **'Create your first piece'**
  String get createFirstPiece;

  /// No description provided for @noMatchingPieces.
  ///
  /// In en, this message translates to:
  /// **'No matching pieces'**
  String get noMatchingPieces;

  /// No description provided for @clearSearchAndFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear search and filters'**
  String get clearSearchAndFilters;

  /// No description provided for @ceramic.
  ///
  /// In en, this message translates to:
  /// **'Ceramic'**
  String get ceramic;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @clayType.
  ///
  /// In en, this message translates to:
  /// **'Clay type'**
  String get clayType;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @dimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get dimensions;

  /// No description provided for @optionalMeasurementSystem.
  ///
  /// In en, this message translates to:
  /// **'Optional · {system}'**
  String optionalMeasurementSystem(String system);

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @width.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// No description provided for @depth.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get depth;

  /// No description provided for @diameter.
  ///
  /// In en, this message translates to:
  /// **'Diameter'**
  String get diameter;

  /// No description provided for @glazeApplications.
  ///
  /// In en, this message translates to:
  /// **'Glaze applications'**
  String get glazeApplications;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @projectNotes.
  ///
  /// In en, this message translates to:
  /// **'Project notes'**
  String get projectNotes;

  /// No description provided for @outcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get outcome;

  /// No description provided for @optionalResultNotes.
  ///
  /// In en, this message translates to:
  /// **'Optional result notes'**
  String get optionalResultNotes;

  /// No description provided for @outcomeHint.
  ///
  /// In en, this message translates to:
  /// **'How did the piece turn out?'**
  String get outcomeHint;

  /// No description provided for @selectFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Select from gallery'**
  String get selectFromGallery;

  /// No description provided for @takePicture.
  ///
  /// In en, this message translates to:
  /// **'Take a picture'**
  String get takePicture;

  /// No description provided for @titleValidation.
  ///
  /// In en, this message translates to:
  /// **'Enter a title up to 255 characters'**
  String get titleValidation;

  /// No description provided for @invalidStage.
  ///
  /// In en, this message translates to:
  /// **'Invalid stage selected'**
  String get invalidStage;

  /// No description provided for @ceramicFieldsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check rating, weight, and note lengths before saving.'**
  String get ceramicFieldsInvalid;

  /// No description provided for @addFiring.
  ///
  /// In en, this message translates to:
  /// **'Add firing'**
  String get addFiring;

  /// No description provided for @editFiring.
  ///
  /// In en, this message translates to:
  /// **'Edit firing'**
  String get editFiring;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @firingType.
  ///
  /// In en, this message translates to:
  /// **'Firing type'**
  String get firingType;

  /// No description provided for @firingBisque.
  ///
  /// In en, this message translates to:
  /// **'Bisque'**
  String get firingBisque;

  /// No description provided for @firingGlaze.
  ///
  /// In en, this message translates to:
  /// **'Glaze'**
  String get firingGlaze;

  /// No description provided for @firingSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get firingSingle;

  /// No description provided for @firingOverglaze.
  ///
  /// In en, this message translates to:
  /// **'Overglaze / luster'**
  String get firingOverglaze;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @firingDate.
  ///
  /// In en, this message translates to:
  /// **'Firing date'**
  String get firingDate;

  /// No description provided for @targetCone.
  ///
  /// In en, this message translates to:
  /// **'Target cone'**
  String get targetCone;

  /// No description provided for @targetTemperature.
  ///
  /// In en, this message translates to:
  /// **'Target temperature'**
  String get targetTemperature;

  /// No description provided for @observedCone.
  ///
  /// In en, this message translates to:
  /// **'Observed cone'**
  String get observedCone;

  /// No description provided for @peakTemperature.
  ///
  /// In en, this message translates to:
  /// **'Peak temperature'**
  String get peakTemperature;

  /// No description provided for @kiln.
  ///
  /// In en, this message translates to:
  /// **'Kiln'**
  String get kiln;

  /// No description provided for @program.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get program;

  /// No description provided for @firingNote.
  ///
  /// In en, this message translates to:
  /// **'Firing note'**
  String get firingNote;

  /// No description provided for @firingSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The firing could not be saved. Please try again.'**
  String get firingSaveFailed;

  /// No description provided for @noGlazeApplications.
  ///
  /// In en, this message translates to:
  /// **'No glaze applications yet.'**
  String get noGlazeApplications;

  /// No description provided for @coatCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 coat} other {{count} coats}}'**
  String coatCount(int count);

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @removeApplication.
  ///
  /// In en, this message translates to:
  /// **'Remove application'**
  String get removeApplication;

  /// No description provided for @addGlazeApplication.
  ///
  /// In en, this message translates to:
  /// **'Add glaze application'**
  String get addGlazeApplication;

  /// No description provided for @unknownGlaze.
  ///
  /// In en, this message translates to:
  /// **'Unknown glaze'**
  String get unknownGlaze;

  /// No description provided for @coatCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Coat count'**
  String get coatCountLabel;

  /// No description provided for @applicationNote.
  ///
  /// In en, this message translates to:
  /// **'Application note'**
  String get applicationNote;

  /// No description provided for @coatMinimum.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one coat.'**
  String get coatMinimum;

  /// No description provided for @glazeApplicationSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The glaze application could not be saved. Please try again.'**
  String get glazeApplicationSaveFailed;

  /// No description provided for @deleteCeramic.
  ///
  /// In en, this message translates to:
  /// **'Delete ceramic'**
  String get deleteCeramic;

  /// No description provided for @deleteCeramicQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this ceramic?'**
  String get deleteCeramicQuestion;

  /// No description provided for @deleteCeramicFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete ceramic.'**
  String get deleteCeramicFailed;

  /// No description provided for @firings.
  ///
  /// In en, this message translates to:
  /// **'Firings'**
  String get firings;

  /// No description provided for @firingRecordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No records} =1 {1 record} other {{count} records}}'**
  String firingRecordCount(int count);

  /// No description provided for @noFiringRecords.
  ///
  /// In en, this message translates to:
  /// **'No firing records yet.'**
  String get noFiringRecords;

  /// No description provided for @coneValue.
  ///
  /// In en, this message translates to:
  /// **'Cone {cone}'**
  String coneValue(String cone);

  /// No description provided for @deleteFiring.
  ///
  /// In en, this message translates to:
  /// **'Delete firing'**
  String get deleteFiring;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @stageEventCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No stage events} =1 {1 stage event} other {{count} stage events}}'**
  String stageEventCount(int count);

  /// No description provided for @updatedOn.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String updatedOn(String date);

  /// No description provided for @historyStartedAt.
  ///
  /// In en, this message translates to:
  /// **'History started at {stage}'**
  String historyStartedAt(String stage);

  /// No description provided for @startedAtStage.
  ///
  /// In en, this message translates to:
  /// **'Started at {stage}'**
  String startedAtStage(String stage);

  /// No description provided for @stageTransition.
  ///
  /// In en, this message translates to:
  /// **'{fromStage} → {toStage}'**
  String stageTransition(String fromStage, String toStage);

  /// No description provided for @deleteFiringQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete firing record?'**
  String get deleteFiringQuestion;

  /// No description provided for @deleteFiringExplanation.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove the {type} record.'**
  String deleteFiringExplanation(String type);

  /// No description provided for @deleteFiringFailed.
  ///
  /// In en, this message translates to:
  /// **'The firing record could not be deleted.'**
  String get deleteFiringFailed;

  /// No description provided for @bisqueFiring.
  ///
  /// In en, this message translates to:
  /// **'Bisque firing'**
  String get bisqueFiring;

  /// No description provided for @glazeFiring.
  ///
  /// In en, this message translates to:
  /// **'Glaze firing'**
  String get glazeFiring;

  /// No description provided for @singleFiring.
  ///
  /// In en, this message translates to:
  /// **'Single firing'**
  String get singleFiring;

  /// No description provided for @overglazeFiring.
  ///
  /// In en, this message translates to:
  /// **'Overglaze / luster firing'**
  String get overglazeFiring;

  /// No description provided for @otherFiring.
  ///
  /// In en, this message translates to:
  /// **'Other firing'**
  String get otherFiring;

  /// No description provided for @clayBodies.
  ///
  /// In en, this message translates to:
  /// **'Clay bodies'**
  String get clayBodies;

  /// No description provided for @clayBody.
  ///
  /// In en, this message translates to:
  /// **'Clay body'**
  String get clayBody;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @clayNotes.
  ///
  /// In en, this message translates to:
  /// **'Clay notes'**
  String get clayNotes;

  /// No description provided for @materialFieldsTooLong.
  ///
  /// In en, this message translates to:
  /// **'Supplier and notes must be at most 255 characters.'**
  String get materialFieldsTooLong;

  /// No description provided for @deleteClay.
  ///
  /// In en, this message translates to:
  /// **'Delete clay'**
  String get deleteClay;

  /// No description provided for @deleteClayQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this clay?'**
  String get deleteClayQuestion;

  /// No description provided for @deleteClayFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete clay.'**
  String get deleteClayFailed;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get enterTitle;

  /// No description provided for @deleteGlaze.
  ///
  /// In en, this message translates to:
  /// **'Delete glaze'**
  String get deleteGlaze;

  /// No description provided for @deleteGlazeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this glaze?'**
  String get deleteGlazeQuestion;

  /// No description provided for @glazeCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'Glaze cannot be deleted'**
  String get glazeCannotDelete;

  /// No description provided for @deleteImageQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete image?'**
  String get deleteImageQuestion;

  /// No description provided for @cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotUndo;

  /// No description provided for @tag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get tag;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @searchAccounts.
  ///
  /// In en, this message translates to:
  /// **'Search accounts'**
  String get searchAccounts;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @archivedChats.
  ///
  /// In en, this message translates to:
  /// **'Archived chats'**
  String get archivedChats;

  /// No description provided for @noArchivedChats.
  ///
  /// In en, this message translates to:
  /// **'No archived chats.'**
  String get noArchivedChats;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @waitingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {None waiting} =1 {1 waiting} other {{count} waiting}}'**
  String waitingCount(int count);

  /// No description provided for @noMessageRequests.
  ///
  /// In en, this message translates to:
  /// **'No message requests.'**
  String get noMessageRequests;

  /// No description provided for @messageUser.
  ///
  /// In en, this message translates to:
  /// **'Message {username}'**
  String messageUser(String username);

  /// No description provided for @messageRequestPreviewExplanation.
  ///
  /// In en, this message translates to:
  /// **'You can send one preview. You can send more messages after they accept.'**
  String get messageRequestPreviewExplanation;

  /// No description provided for @writeMessageRequest.
  ///
  /// In en, this message translates to:
  /// **'Write a message request…'**
  String get writeMessageRequest;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @selectFriendsMemberCount.
  ///
  /// In en, this message translates to:
  /// **'Select friends · {count}/50 members'**
  String selectFriendsMemberCount(int count);

  /// No description provided for @addFriendBeforeGroup.
  ///
  /// In en, this message translates to:
  /// **'Add a friend before creating a group.'**
  String get addFriendBeforeGroup;

  /// No description provided for @addMembers.
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get addMembers;

  /// No description provided for @chooseFriendsLimit.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {count} of your friends. Existing members are rejected safely.'**
  String chooseFriendsLimit(int count);

  /// No description provided for @reportMessage.
  ///
  /// In en, this message translates to:
  /// **'Report message'**
  String get reportMessage;

  /// No description provided for @reportReasonQuestion.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this message?'**
  String get reportReasonQuestion;

  /// No description provided for @reportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportSpam;

  /// No description provided for @reportHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportHarassment;

  /// No description provided for @reportHate.
  ///
  /// In en, this message translates to:
  /// **'Hate'**
  String get reportHate;

  /// No description provided for @reportSexualContent.
  ///
  /// In en, this message translates to:
  /// **'Sexual content'**
  String get reportSexualContent;

  /// No description provided for @reportViolence.
  ///
  /// In en, this message translates to:
  /// **'Violence'**
  String get reportViolence;

  /// No description provided for @reportChooseReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason for this report.'**
  String get reportChooseReason;

  /// No description provided for @reportOtherExplanationRequired.
  ///
  /// In en, this message translates to:
  /// **'Add an explanation when choosing Other.'**
  String get reportOtherExplanationRequired;

  /// No description provided for @reportExplanationTooLong.
  ///
  /// In en, this message translates to:
  /// **'The explanation must contain at most 1000 characters.'**
  String get reportExplanationTooLong;

  /// No description provided for @reportExplanationOptional.
  ///
  /// In en, this message translates to:
  /// **'Explanation (optional)'**
  String get reportExplanationOptional;

  /// No description provided for @reportExplanationHint.
  ///
  /// In en, this message translates to:
  /// **'Add details that may help a future review.'**
  String get reportExplanationHint;

  /// No description provided for @messageBeingReported.
  ///
  /// In en, this message translates to:
  /// **'Message being reported'**
  String get messageBeingReported;

  /// No description provided for @reportEvidenceDisclosure.
  ///
  /// In en, this message translates to:
  /// **'The selected message and up to two nearby messages on each side will be securely included for review. Reporting does not block this account or change the conversation.'**
  String get reportEvidenceDisclosure;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @noGroupChats.
  ///
  /// In en, this message translates to:
  /// **'No group chats yet.'**
  String get noGroupChats;

  /// No description provided for @noUnreadChats.
  ///
  /// In en, this message translates to:
  /// **'No unread chats.'**
  String get noUnreadChats;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet. Search for an account to get started.'**
  String get noConversations;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get now;

  /// No description provided for @relativeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String relativeMinutes(int count);

  /// No description provided for @relativeHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String relativeHours(int count);

  /// No description provided for @relativeDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String relativeDays(int count);

  /// No description provided for @accountBlocked.
  ///
  /// In en, this message translates to:
  /// **'{username} blocked'**
  String accountBlocked(String username);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @noReceivedRequests.
  ///
  /// In en, this message translates to:
  /// **'No received requests.'**
  String get noReceivedRequests;

  /// No description provided for @noSentRequests.
  ///
  /// In en, this message translates to:
  /// **'No sent requests.'**
  String get noSentRequests;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get requestSent;

  /// No description provided for @wantsToBeFriends.
  ///
  /// In en, this message translates to:
  /// **'Wants to be friends'**
  String get wantsToBeFriends;

  /// No description provided for @comingLater.
  ///
  /// In en, this message translates to:
  /// **'Coming later'**
  String get comingLater;

  /// No description provided for @renameGroup.
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get renameGroup;

  /// No description provided for @leaveGroupQuestion.
  ///
  /// In en, this message translates to:
  /// **'Leave group?'**
  String get leaveGroupQuestion;

  /// No description provided for @leaveGroupExplanation.
  ///
  /// In en, this message translates to:
  /// **'You will keep read-only history from your membership periods.'**
  String get leaveGroupExplanation;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroup;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Blocking is a separate action.'**
  String get reportSubmitted;

  /// No description provided for @memberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 member} other {{count} members}}'**
  String memberCount(int count);

  /// No description provided for @archiveChat.
  ///
  /// In en, this message translates to:
  /// **'Archive chat'**
  String get archiveChat;

  /// No description provided for @conversationReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This conversation is read-only.'**
  String get conversationReadOnly;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation.'**
  String get startConversation;

  /// No description provided for @loadEarlierMessages.
  ///
  /// In en, this message translates to:
  /// **'Load earlier messages'**
  String get loadEarlierMessages;

  /// No description provided for @messageActionsHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press for message actions'**
  String get messageActionsHint;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @voiceMessageComingLater.
  ///
  /// In en, this message translates to:
  /// **'Voice message — coming later'**
  String get voiceMessageComingLater;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message…'**
  String get messageHint;

  /// No description provided for @emojiComingLater.
  ///
  /// In en, this message translates to:
  /// **'Emoji — coming later'**
  String get emojiComingLater;

  /// No description provided for @imageComingLater.
  ///
  /// In en, this message translates to:
  /// **'Image — coming later'**
  String get imageComingLater;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @removeFriendQuestion.
  ///
  /// In en, this message translates to:
  /// **'Remove friend?'**
  String get removeFriendQuestion;

  /// No description provided for @removeFriendExplanation.
  ///
  /// In en, this message translates to:
  /// **'You and {username} will no longer be friends.'**
  String removeFriendExplanation(String username);

  /// No description provided for @blockUserQuestion.
  ///
  /// In en, this message translates to:
  /// **'Block {username}?'**
  String blockUserQuestion(String username);

  /// No description provided for @blockExplanation.
  ///
  /// In en, this message translates to:
  /// **'You will disappear from each other’s search, profiles, friend lists, and requests. Existing friendship and requests are cancelled.'**
  String get blockExplanation;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @sendFriendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send friend request'**
  String get sendFriendRequest;

  /// No description provided for @acceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Accept request'**
  String get acceptRequest;

  /// No description provided for @declineRequest.
  ///
  /// In en, this message translates to:
  /// **'Decline request'**
  String get declineRequest;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @sendMessageRequest.
  ///
  /// In en, this message translates to:
  /// **'Send message request'**
  String get sendMessageRequest;

  /// No description provided for @removeFriend.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get removeFriend;

  /// No description provided for @blockAccount.
  ///
  /// In en, this message translates to:
  /// **'Block account'**
  String get blockAccount;

  /// No description provided for @relationshipFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get relationshipFriends;

  /// No description provided for @friendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get friendRequestSent;

  /// No description provided for @previouslyDeclined.
  ///
  /// In en, this message translates to:
  /// **'You previously declined this request'**
  String get previouslyDeclined;

  /// No description provided for @friendRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Friend request declined'**
  String get friendRequestDeclined;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @friend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get friend;

  /// No description provided for @incomingRequest.
  ///
  /// In en, this message translates to:
  /// **'Incoming request'**
  String get incomingRequest;

  /// No description provided for @searchFriends.
  ///
  /// In en, this message translates to:
  /// **'Search friends'**
  String get searchFriends;

  /// No description provided for @noFriendsFound.
  ///
  /// In en, this message translates to:
  /// **'No friends found.'**
  String get noFriendsFound;

  /// No description provided for @searchMinimumCharacters.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 3 characters to search accounts.'**
  String get searchMinimumCharacters;

  /// No description provided for @noAccountsFound.
  ///
  /// In en, this message translates to:
  /// **'No accounts found.'**
  String get noAccountsFound;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @finishedPieces.
  ///
  /// In en, this message translates to:
  /// **'Finished pieces'**
  String get finishedPieces;

  /// No description provided for @finishedPiecesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Pieces moved to Finished will appear here.'**
  String get finishedPiecesEmpty;

  /// No description provided for @viewPhoto.
  ///
  /// In en, this message translates to:
  /// **'View photo'**
  String get viewPhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get uploadPhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @profilePhotoPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Profile photos are public. Cached copies may remain after removal.'**
  String get profilePhotoPrivacy;

  /// No description provided for @forename.
  ///
  /// In en, this message translates to:
  /// **'Forename'**
  String get forename;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @readOnlyFields.
  ///
  /// In en, this message translates to:
  /// **'These fields are read-only for now.'**
  String get readOnlyFields;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @photoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load photo'**
  String get photoLoadFailed;
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
      <String>['da', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

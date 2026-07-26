// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get appTitle => 'Keramik';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try again';

  @override
  String get add => 'Add';

  @override
  String get create => 'Create';

  @override
  String get edit => 'Edit';

  @override
  String get remove => 'Remove';

  @override
  String get send => 'Send';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get restore => 'Restore';

  @override
  String get clear => 'Clear';

  @override
  String get ok => 'OK';

  @override
  String get loading => 'Loading…';

  @override
  String get loadMore => 'Load more';

  @override
  String get pleaseWait => 'Please wait…';

  @override
  String get noMessages => 'No messages';

  @override
  String errorWithDetails(String details) {
    return 'Error: $details';
  }

  @override
  String get stageIdeas => 'Ideas';

  @override
  String get stageThrown => 'Thrown';

  @override
  String get stageTrimmed => 'Trimmed';

  @override
  String get stageBisqued => 'Bisqued';

  @override
  String get stageGlazed => 'Glazed';

  @override
  String get stageFinished => 'Finished';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get measurementMetric => 'Metric';

  @override
  String get measurementImperial => 'Imperial';

  @override
  String get privacyEveryone => 'Everyone';

  @override
  String get privacyFriends => 'Friends';

  @override
  String get privacyFriendsOfFriends => 'Friends of friends';

  @override
  String get privacyNoOne => 'No one';

  @override
  String get settingsLoadFailed =>
      'Settings could not be loaded. Check your connection and retry.';

  @override
  String get settingSaveFailed =>
      'That setting could not be saved. Your previous choice was restored.';

  @override
  String get settingsAndPrivacy => 'Settings and privacy';

  @override
  String get settingsAccount => 'Account';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get accountInformation => 'Account information';

  @override
  String get passwordAndSecurity => 'Password and security';

  @override
  String get downloadYourData => 'Download your data';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get discoverability => 'Discoverability';

  @override
  String get whoCanDiscover => 'Who can discover your account?';

  @override
  String get friendRequests => 'Friend requests';

  @override
  String get whoCanSendFriendRequests => 'Who can send friend requests?';

  @override
  String get messages => 'Messages';

  @override
  String get whoCanSendMessageRequests => 'Who can send message requests?';

  @override
  String get blockedAccounts => 'Blocked accounts';

  @override
  String get contentAndDisplay => 'Content and display';

  @override
  String get notifications => 'Notifications';

  @override
  String get appearance => 'Appearance';

  @override
  String get units => 'Units';

  @override
  String get language => 'Language';

  @override
  String get supportAndAbout => 'Support and about';

  @override
  String get websiteHelpCenter => 'Website help center';

  @override
  String get privacyInformation => 'Privacy information';

  @override
  String get aboutKeramik => 'About Keramik';

  @override
  String get loginSection => 'Login';

  @override
  String get logOut => 'Log out';

  @override
  String get loggingOut => 'Logging out…';

  @override
  String get logOutQuestion => 'Log out?';

  @override
  String get logOutExplanation =>
      'You can sign back in with your email or username.';

  @override
  String get logoutFailed =>
      'Logout failed. Your session is still active; please retry.';

  @override
  String get linkOpenFailed => 'The link could not be opened.';

  @override
  String get currentLanguage => 'Current language';

  @override
  String get languageSaveFailed =>
      'The language could not be saved. Your previous language was restored.';

  @override
  String get username => 'Username';

  @override
  String get name => 'Name';

  @override
  String get publicUserId => 'Public user ID';

  @override
  String get accountInformationPrivacyNote =>
      'Your public user ID is used for profile links and cannot be changed.';

  @override
  String get accountInformationLoadFailed =>
      'Account information could not be loaded.';

  @override
  String get accountEmailPrivacyNote =>
      'Your email address is private. For security, account email changes are handled through support.';

  @override
  String get notSet => 'Not set';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordLengthHelp => 'Use 8–128 characters.';

  @override
  String get changePassword => 'Change password';

  @override
  String get websitePasswordPage => 'Use the website password page';

  @override
  String get passwordsDoNotMatch => 'The new passwords do not match.';

  @override
  String get passwordChanged =>
      'Password changed. Other sessions have been signed out.';

  @override
  String get passwordChangeFailed =>
      'Password could not be changed. Please retry.';

  @override
  String get dataExportDescription =>
      'Your ZIP includes JSON/CSV records, preferences, relationships, accessible conversation data, and server-stored profile, ceramic, and clay images.';

  @override
  String get dataExportLimit =>
      'Only one export can run at a time. Completed packages expire after seven days.';

  @override
  String get exportRequestFailed => 'The export could not be requested.';

  @override
  String get exportRefreshFailed => 'Export status could not be refreshed.';

  @override
  String get exportDownloadFailed =>
      'The ZIP could not be downloaded or opened.';

  @override
  String availableUntil(String date) {
    return 'Available until $date';
  }

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get downloadZip => 'Download ZIP';

  @override
  String get createExport => 'Create export';

  @override
  String get exportQueued => 'Export queued';

  @override
  String get exportCreating => 'Creating your export';

  @override
  String get exportReady => 'Export ready';

  @override
  String get exportExpired => 'Export expired';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get deletionScheduleFailed =>
      'Deletion could not be scheduled. Please retry.';

  @override
  String get deletionCancellationPeriod =>
      'Deletion starts a 30-day cancellation period.';

  @override
  String get deletionSignOutExplanation =>
      'You will be signed out everywhere immediately and cannot use ordinary app features. Sign in again during the next 30 days to cancel deletion or sign out.';

  @override
  String get deletionRetentionExplanation =>
      'After 30 days, private identity, journal and material data, and owned media are erased. A disabled pseudonymous account shell and shared chat, report, audit, and safety records are retained indefinitely. Other members will see “Deleted member.”';

  @override
  String get deletionUnderstand => 'I understand what is erased and retained.';

  @override
  String get typeDeleteToConfirm => 'Type DELETE to confirm';

  @override
  String get scheduleAccountDeletion => 'Schedule account deletion';

  @override
  String get directMessages => 'Direct messages';

  @override
  String get messageRequests => 'Message requests';

  @override
  String get groupActivity => 'Group activity';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get pushNotificationsComingLater =>
      'Coming later. Keramik does not deliver notifications while the app is suspended.';

  @override
  String get blockedAccountsLoadFailed =>
      'Blocked accounts could not be loaded.';

  @override
  String accountUnblockFailed(String username) {
    return '$username could not be unblocked.';
  }

  @override
  String get noBlockedAccounts => 'You have not blocked any accounts.';

  @override
  String get unblock => 'Unblock';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get signInToAccount => 'Sign in to your account';

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get logIn => 'Log in';

  @override
  String get accountDeletionPending => 'Account deletion pending';

  @override
  String get accountDeletionPendingExplanation =>
      'Ordinary activity is restricted during the 30-day grace period. Cancel deletion to restore the account, or sign out.';

  @override
  String get cancelDeletion => 'Cancel deletion';

  @override
  String get signOut => 'Sign out';

  @override
  String get or => 'OR';

  @override
  String get noAccountQuestion => 'Don’t have an account? ';

  @override
  String get signUp => 'Sign up';

  @override
  String get materials => 'Materials';

  @override
  String get clays => 'Clays';

  @override
  String get glazes => 'Glazes';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationMaterials => 'Materials';

  @override
  String get navigationShop => 'Shop';

  @override
  String get navigationChats => 'Chats';

  @override
  String get navigationProfile => 'Profile';

  @override
  String get ceramicJournal => 'Ceramic journal';

  @override
  String get journalLoadFailed => 'We could not load your ceramic journal.';

  @override
  String get createCeramic => 'Create ceramic';

  @override
  String get journalSearchHint => 'Search titles, notes, tags, clay, or glaze';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get filters => 'Filters';

  @override
  String get descending => 'Descending';

  @override
  String get ascending => 'Ascending';

  @override
  String pieceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pieces',
      one: '1 piece',
      zero: 'No pieces',
    );
    return '$_temp0';
  }

  @override
  String get unknownStage => 'Unknown stage';

  @override
  String get filterJournal => 'Filter journal';

  @override
  String get stage => 'Stage';

  @override
  String get clay => 'Clay';

  @override
  String get glaze => 'Glaze';

  @override
  String get minimumRating => 'Minimum rating';

  @override
  String get tags => 'Tags';

  @override
  String get sortRecentlyUpdated => 'Recently updated';

  @override
  String get title => 'Title';

  @override
  String get rating => 'Rating';

  @override
  String get creationDate => 'Creation date';

  @override
  String get startCeramicJournal => 'Start your ceramic journal';

  @override
  String get emptyJournalDescription =>
      'Capture your first piece, materials, process, and results.';

  @override
  String get createFirstPiece => 'Create your first piece';

  @override
  String get noMatchingPieces => 'No matching pieces';

  @override
  String get clearSearchAndFilters => 'Clear search and filters';

  @override
  String get ceramic => 'Ceramic';

  @override
  String get progress => 'Progress';

  @override
  String get information => 'Information';

  @override
  String get clayType => 'Clay type';

  @override
  String get select => 'Select';

  @override
  String get weight => 'Weight';

  @override
  String get dimensions => 'Dimensions';

  @override
  String optionalMeasurementSystem(String system) {
    return 'Optional · $system';
  }

  @override
  String get height => 'Height';

  @override
  String get width => 'Width';

  @override
  String get depth => 'Depth';

  @override
  String get diameter => 'Diameter';

  @override
  String get glazeApplications => 'Glaze applications';

  @override
  String get rate => 'Rate';

  @override
  String get notes => 'Notes';

  @override
  String get projectNotes => 'Project notes';

  @override
  String get outcome => 'Outcome';

  @override
  String get optionalResultNotes => 'Optional result notes';

  @override
  String get outcomeHint => 'How did the piece turn out?';

  @override
  String get selectFromGallery => 'Select from gallery';

  @override
  String get takePicture => 'Take a picture';

  @override
  String get titleValidation => 'Enter a title up to 255 characters';

  @override
  String get invalidStage => 'Invalid stage selected';

  @override
  String get ceramicFieldsInvalid =>
      'Check rating, weight, and note lengths before saving.';

  @override
  String get addFiring => 'Add firing';

  @override
  String get editFiring => 'Edit firing';

  @override
  String get status => 'Status';

  @override
  String get planned => 'Planned';

  @override
  String get completed => 'Completed';

  @override
  String get firingType => 'Firing type';

  @override
  String get firingBisque => 'Bisque';

  @override
  String get firingGlaze => 'Glaze';

  @override
  String get firingSingle => 'Single';

  @override
  String get firingOverglaze => 'Overglaze / luster';

  @override
  String get other => 'Other';

  @override
  String get firingDate => 'Firing date';

  @override
  String get targetCone => 'Target cone';

  @override
  String get targetTemperature => 'Target temperature';

  @override
  String get observedCone => 'Observed cone';

  @override
  String get peakTemperature => 'Peak temperature';

  @override
  String get kiln => 'Kiln';

  @override
  String get program => 'Program';

  @override
  String get firingNote => 'Firing note';

  @override
  String get firingSaveFailed =>
      'The firing could not be saved. Please try again.';

  @override
  String get noGlazeApplications => 'No glaze applications yet.';

  @override
  String coatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coats',
      one: '1 coat',
    );
    return '$_temp0';
  }

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get removeApplication => 'Remove application';

  @override
  String get addGlazeApplication => 'Add glaze application';

  @override
  String get unknownGlaze => 'Unknown glaze';

  @override
  String get coatCountLabel => 'Coat count';

  @override
  String get applicationNote => 'Application note';

  @override
  String get coatMinimum => 'Enter at least one coat.';

  @override
  String get glazeApplicationSaveFailed =>
      'The glaze application could not be saved. Please try again.';

  @override
  String get deleteCeramic => 'Delete ceramic';

  @override
  String get deleteCeramicQuestion =>
      'Are you sure you want to delete this ceramic?';

  @override
  String get deleteCeramicFailed => 'Could not delete ceramic.';

  @override
  String get firings => 'Firings';

  @override
  String firingRecordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
      zero: 'No records',
    );
    return '$_temp0';
  }

  @override
  String get noFiringRecords => 'No firing records yet.';

  @override
  String coneValue(String cone) {
    return 'Cone $cone';
  }

  @override
  String get deleteFiring => 'Delete firing';

  @override
  String get history => 'History';

  @override
  String stageEventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stage events',
      one: '1 stage event',
      zero: 'No stage events',
    );
    return '$_temp0';
  }

  @override
  String updatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String historyStartedAt(String stage) {
    return 'History started at $stage';
  }

  @override
  String startedAtStage(String stage) {
    return 'Started at $stage';
  }

  @override
  String stageTransition(String fromStage, String toStage) {
    return '$fromStage → $toStage';
  }

  @override
  String get deleteFiringQuestion => 'Delete firing record?';

  @override
  String deleteFiringExplanation(String type) {
    return 'This will permanently remove the $type record.';
  }

  @override
  String get deleteFiringFailed => 'The firing record could not be deleted.';

  @override
  String get bisqueFiring => 'Bisque firing';

  @override
  String get glazeFiring => 'Glaze firing';

  @override
  String get singleFiring => 'Single firing';

  @override
  String get overglazeFiring => 'Overglaze / luster firing';

  @override
  String get otherFiring => 'Other firing';

  @override
  String get clayBodies => 'Clay bodies';

  @override
  String get clayBody => 'Clay body';

  @override
  String get supplier => 'Supplier';

  @override
  String get clayNotes => 'Clay notes';

  @override
  String get materialFieldsTooLong =>
      'Supplier and notes must be at most 255 characters.';

  @override
  String get deleteClay => 'Delete clay';

  @override
  String get deleteClayQuestion => 'Are you sure you want to delete this clay?';

  @override
  String get deleteClayFailed => 'Could not delete clay.';

  @override
  String get enterTitle => 'Enter a title';

  @override
  String get deleteGlaze => 'Delete glaze';

  @override
  String get deleteGlazeQuestion =>
      'Are you sure you want to delete this glaze?';

  @override
  String get glazeCannotDelete => 'Glaze cannot be deleted';

  @override
  String get deleteImageQuestion => 'Delete image?';

  @override
  String get cannotUndo => 'This action cannot be undone.';

  @override
  String get tag => 'Tag';

  @override
  String get chats => 'Chats';

  @override
  String get searchAccounts => 'Search accounts';

  @override
  String get newGroup => 'New group';

  @override
  String get archivedChats => 'Archived chats';

  @override
  String get noArchivedChats => 'No archived chats.';

  @override
  String get requests => 'Requests';

  @override
  String waitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting',
      one: '1 waiting',
      zero: 'None waiting',
    );
    return '$_temp0';
  }

  @override
  String get noMessageRequests => 'No message requests.';

  @override
  String messageUser(String username) {
    return 'Message $username';
  }

  @override
  String get messageRequestPreviewExplanation =>
      'You can send one preview. You can send more messages after they accept.';

  @override
  String get writeMessageRequest => 'Write a message request…';

  @override
  String get sendRequest => 'Send request';

  @override
  String get groupName => 'Group name';

  @override
  String selectFriendsMemberCount(int count) {
    return 'Select friends · $count/50 members';
  }

  @override
  String get addFriendBeforeGroup => 'Add a friend before creating a group.';

  @override
  String get addMembers => 'Add members';

  @override
  String chooseFriendsLimit(int count) {
    return 'Choose up to $count of your friends. Existing members are rejected safely.';
  }

  @override
  String get reportMessage => 'Report message';

  @override
  String get reportReasonQuestion => 'Why are you reporting this message?';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportHarassment => 'Harassment';

  @override
  String get reportHate => 'Hate';

  @override
  String get reportSexualContent => 'Sexual content';

  @override
  String get reportViolence => 'Violence';

  @override
  String get reportChooseReason => 'Choose a reason for this report.';

  @override
  String get reportOtherExplanationRequired =>
      'Add an explanation when choosing Other.';

  @override
  String get reportExplanationTooLong =>
      'The explanation must contain at most 1000 characters.';

  @override
  String get reportExplanationOptional => 'Explanation (optional)';

  @override
  String get reportExplanationHint =>
      'Add details that may help a future review.';

  @override
  String get messageBeingReported => 'Message being reported';

  @override
  String get reportEvidenceDisclosure =>
      'The selected message and up to two nearby messages on each side will be securely included for review. Reporting does not block this account or change the conversation.';

  @override
  String get submitReport => 'Submit report';

  @override
  String get all => 'All';

  @override
  String get unread => 'Unread';

  @override
  String get groups => 'Groups';

  @override
  String get noGroupChats => 'No group chats yet.';

  @override
  String get noUnreadChats => 'No unread chats.';

  @override
  String get noConversations =>
      'No conversations yet. Search for an account to get started.';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get now => 'now';

  @override
  String relativeMinutes(int count) {
    return '${count}m';
  }

  @override
  String relativeHours(int count) {
    return '${count}h';
  }

  @override
  String relativeDays(int count) {
    return '${count}d';
  }

  @override
  String accountBlocked(String username) {
    return '$username blocked';
  }

  @override
  String get undo => 'Undo';

  @override
  String get received => 'Received';

  @override
  String get sent => 'Sent';

  @override
  String get noReceivedRequests => 'No received requests.';

  @override
  String get noSentRequests => 'No sent requests.';

  @override
  String get requestSent => 'Request sent';

  @override
  String get wantsToBeFriends => 'Wants to be friends';

  @override
  String get comingLater => 'Coming later';

  @override
  String get renameGroup => 'Rename group';

  @override
  String get leaveGroupQuestion => 'Leave group?';

  @override
  String get leaveGroupExplanation =>
      'You will keep read-only history from your membership periods.';

  @override
  String get leave => 'Leave';

  @override
  String get leaveGroup => 'Leave group';

  @override
  String get reportSubmitted =>
      'Report submitted. Blocking is a separate action.';

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get archiveChat => 'Archive chat';

  @override
  String get conversationReadOnly => 'This conversation is read-only.';

  @override
  String get startConversation => 'Start the conversation.';

  @override
  String get loadEarlierMessages => 'Load earlier messages';

  @override
  String get messageActionsHint => 'Long-press for message actions';

  @override
  String get today => 'Today';

  @override
  String get voiceMessageComingLater => 'Voice message — coming later';

  @override
  String get messageHint => 'Message…';

  @override
  String get emojiComingLater => 'Emoji — coming later';

  @override
  String get imageComingLater => 'Image — coming later';

  @override
  String get profile => 'Profile';

  @override
  String get removeFriendQuestion => 'Remove friend?';

  @override
  String removeFriendExplanation(String username) {
    return 'You and $username will no longer be friends.';
  }

  @override
  String blockUserQuestion(String username) {
    return 'Block $username?';
  }

  @override
  String get blockExplanation =>
      'You will disappear from each other’s search, profiles, friend lists, and requests. Existing friendship and requests are cancelled.';

  @override
  String get block => 'Block';

  @override
  String get sendFriendRequest => 'Send friend request';

  @override
  String get acceptRequest => 'Accept request';

  @override
  String get declineRequest => 'Decline request';

  @override
  String get message => 'Message';

  @override
  String get sendMessageRequest => 'Send message request';

  @override
  String get removeFriend => 'Remove friend';

  @override
  String get blockAccount => 'Block account';

  @override
  String get relationshipFriends => 'Friends';

  @override
  String get friendRequestSent => 'Friend request sent';

  @override
  String get previouslyDeclined => 'You previously declined this request';

  @override
  String get friendRequestDeclined => 'Friend request declined';

  @override
  String get account => 'Account';

  @override
  String get friend => 'Friend';

  @override
  String get incomingRequest => 'Incoming request';

  @override
  String get searchFriends => 'Search friends';

  @override
  String get noFriendsFound => 'No friends found.';

  @override
  String get searchMinimumCharacters =>
      'Enter at least 3 characters to search accounts.';

  @override
  String get noAccountsFound => 'No accounts found.';

  @override
  String get accounts => 'Accounts';

  @override
  String get finishedPieces => 'Finished pieces';

  @override
  String get finishedPiecesEmpty =>
      'Pieces moved to Finished will appear here.';

  @override
  String get viewPhoto => 'View photo';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get uploadPhoto => 'Upload photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get profilePhotoPrivacy =>
      'Profile photos are public. Cached copies may remain after removal.';

  @override
  String get forename => 'Forename';

  @override
  String get surname => 'Surname';

  @override
  String get readOnlyFields => 'These fields are read-only for now.';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get photoLoadFailed => 'Unable to load photo';

  @override
  String get shareCeramic => 'Share ceramic';

  @override
  String get shareCeramicDisclosure =>
      'The complete journal entry, including notes, images, and future edits, will be visible to everyone who can see this conversation message.';

  @override
  String get share => 'Share';

  @override
  String get chooseCeramic => 'Choose a ceramic';

  @override
  String get noCeramicsToShare => 'You do not have any ceramics to share yet.';

  @override
  String get shareToConversation => 'Share to a conversation';

  @override
  String get noWritableConversations =>
      'No writable conversations are available. Restore an archived chat or rejoin a group before sharing.';

  @override
  String get directConversation => 'Direct conversation';

  @override
  String get ceramicShared => 'Ceramic shared.';

  @override
  String get ceramicUnavailable => 'This ceramic is no longer available.';

  @override
  String openSharedCeramic(String title) {
    return 'Open shared ceramic $title';
  }

  @override
  String get sharedCeramic => 'Shared ceramic';

  @override
  String get sharedCeramicLoadFailed =>
      'The shared ceramic could not be loaded.';

  @override
  String get ceramicMessagePreview => 'Shared a ceramic';

  @override
  String get reportCeramicEvidenceDisclosure =>
      'The selected ceramic, every visible journal field, all current images, and up to two nearby messages on each side will be securely copied for review. The evidence will not change if the ceramic is edited or deleted. Reporting does not block this account or change the conversation.';

  @override
  String get measurements => 'Measurements';

  @override
  String get noTags => 'No tags.';

  @override
  String get timestamps => 'Timestamps';

  @override
  String get created => 'Created';

  @override
  String get updated => 'Updated';

  @override
  String get navigationDiscover => 'Discover';

  @override
  String get discoverForYou => 'For You';

  @override
  String get discoverLatest => 'Latest';

  @override
  String get discoverEmpty => 'No published ceramics are available yet.';

  @override
  String get notInterestedAction => 'Not interested';

  @override
  String get likeAction => 'Like';

  @override
  String get publishFinishedTitle => 'Publish this finished piece?';

  @override
  String get publishFinishedBody =>
      'Published pieces can appear in Discover and on your profile. Up to 20 images and the listed public details will be visible.';

  @override
  String get publicationAudienceEveryone =>
      'Everyone: Visible to all active members, except people you have blocked or who have blocked you.';

  @override
  String get publicationAudienceFriends =>
      'Friends only: Your current privacy setting limits this piece to accepted friends. Blocking and account rules still apply.';

  @override
  String get publishAction => 'Publish';

  @override
  String get notNowAction => 'Not now';

  @override
  String get unpublishAction => 'Unpublish';

  @override
  String get publicationTemporarilyUnavailable =>
      'Published, but hidden until the piece is Finished and has an image.';

  @override
  String get publicationModerationRemoved =>
      'Removed by moderation. You cannot republish this piece while the moderation lock is active.';

  @override
  String get discoverSessionRefreshed => 'Recommendations refreshed.';

  @override
  String get publicationUnavailable => 'Published ceramic unavailable';

  @override
  String get publicationReportEvidenceDisclosure =>
      'The current public details and up to 20 visible images will be securely preserved for moderator review. Reporting permanently hides this publication episode from you.';

  @override
  String get undoAction => 'Undo';

  @override
  String get reportPublication => 'Report publication';

  @override
  String get reportReason => 'Reason';

  @override
  String get reportExplanation => 'Explanation';
}

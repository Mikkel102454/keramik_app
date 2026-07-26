import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/objects/chat_report_dto.dart';
import 'package:flutter/widgets.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// Temporary source-compatible fallback while the generated localization command
// is unavailable. Generated instance getters take precedence after regeneration.
extension DiscoverAppLocalizations on AppLocalizations {
  bool get _da => localeName.toLowerCase().startsWith('da');
  String get navigationDiscover => _da ? 'Opdag' : 'Discover';
  String get discoverForYou => _da ? 'Til dig' : 'For You';
  String get discoverLatest => _da ? 'Nyeste' : 'Latest';
  String get discoverEmpty => _da
      ? 'Der er endnu ingen udgivne keramikemner.'
      : 'No published ceramics are available yet.';
  String get notInterestedAction =>
      _da ? 'Ikke interesseret' : 'Not interested';
  String get likeAction => _da ? 'Synes godt om' : 'Like';
  String get publishFinishedTitle =>
      _da ? 'Vil du udgive dette færdige emne?' : 'Publish this finished piece?';
  String get publishFinishedBody => _da
      ? 'Udgivne emner kan vises under Opdag og på din profil. Op til 20 billeder og de angivne offentlige oplysninger bliver synlige.'
      : 'Published pieces can appear in Discover and on your profile. Up to 20 images and the listed public details will be visible.';
  String get publishAction => _da ? 'Udgiv' : 'Publish';
  String get notNowAction => _da ? 'Ikke nu' : 'Not now';
  String get unpublishAction => _da ? 'Fjern udgivelse' : 'Unpublish';
  String get publicationTemporarilyUnavailable => _da
      ? 'Udgivet, men skjult indtil emnet er Færdigt og har et billede.'
      : 'Published, but hidden until the piece is Finished and has an image.';
  String get publicationModerationRemoved => _da
      ? 'Fjernet af moderation. Du kan ikke udgive emnet igen, mens moderationslåsen er aktiv.'
      : 'Removed by moderation. You cannot republish this piece while the moderation lock is active.';
  String get publicationUnavailable =>
      _da ? 'Udgivet keramik er ikke tilgængelig' : 'Published ceramic unavailable';
  String get publicationReportEvidenceDisclosure => _da
      ? 'De nuværende offentlige oplysninger og op til 20 synlige billeder gemmes sikkert til moderatorgennemgang. Rapportering skjuler denne udgivelse permanent for dig.'
      : 'The current public details and up to 20 visible images will be securely preserved for moderator review. Reporting permanently hides this publication episode from you.';
  String publicationReportCategory(String value) => switch (value) {
    'SPAM' => reportSpam,
    'HARASSMENT_OR_HATE' => _da ? 'Chikane eller had' : 'Harassment or hate',
    'SEXUAL_CONTENT' => reportSexualContent,
    'VIOLENCE_OR_DANGEROUS' => _da ? 'Vold eller farligt indhold' : 'Violence or dangerous content',
    'STOLEN_WORK_OR_IP' => _da ? 'Stjålet værk eller ophavsret' : 'Stolen work or intellectual property',
    _ => other,
  };
  String get undoAction => _da ? 'Fortryd' : 'Undo';
  String get reportPublication => _da ? 'Rapportér udgivelse' : 'Report publication';
  String get reportReason => _da ? 'Årsag' : 'Reason';
  String get reportExplanation => _da ? 'Forklaring' : 'Explanation';
  String get submitReport => _da ? 'Send rapport' : 'Submit report';
}

extension LocalizedChatReportCategory on ChatReportCategory {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    ChatReportCategory.spam => l10n.reportSpam,
    ChatReportCategory.harassment => l10n.reportHarassment,
    ChatReportCategory.hate => l10n.reportHate,
    ChatReportCategory.sexualContent => l10n.reportSexualContent,
    ChatReportCategory.violence => l10n.reportViolence,
    ChatReportCategory.other => l10n.other,
  };
}

extension LocalizedChatReportValidationError on ChatReportValidationError {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    ChatReportValidationError.chooseReason => l10n.reportChooseReason,
    ChatReportValidationError.otherExplanationRequired =>
      l10n.reportOtherExplanationRequired,
    ChatReportValidationError.explanationTooLong =>
      l10n.reportExplanationTooLong,
  };
}

extension LocalizedAccountThemeMode on AccountThemeMode {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    AccountThemeMode.system => l10n.themeSystem,
    AccountThemeMode.light => l10n.themeLight,
    AccountThemeMode.dark => l10n.themeDark,
  };
}

extension LocalizedMeasurementSystem on MeasurementSystem {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    MeasurementSystem.metric => l10n.measurementMetric,
    MeasurementSystem.imperial => l10n.measurementImperial,
  };
}

extension LocalizedPrivacyAudience on PrivacyAudience {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    PrivacyAudience.everyone => l10n.privacyEveryone,
    PrivacyAudience.friends => l10n.privacyFriends,
    PrivacyAudience.friendsOfFriends => l10n.privacyFriendsOfFriends,
    PrivacyAudience.noOne => l10n.privacyNoOne,
  };
}

String localizedStageName(AppLocalizations l10n, String canonicalName) {
  return switch (canonicalName) {
    'Ideas' => l10n.stageIdeas,
    'Thrown' => l10n.stageThrown,
    'Trimmed' => l10n.stageTrimmed,
    'Bisqued' => l10n.stageBisqued,
    'Glazed' => l10n.stageGlazed,
    'Finished' => l10n.stageFinished,
    _ => canonicalName,
  };
}

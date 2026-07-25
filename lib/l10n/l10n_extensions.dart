import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/objects/chat_report_dto.dart';
import 'package:flutter/widgets.dart';

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
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

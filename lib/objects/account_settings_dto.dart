import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const supportedExchangeCurrencies = <String>[
  'EUR',
  'DKK',
  'USD',
  'GBP',
  'SEK',
  'NOK',
  'CHF',
  'ISK',
  'AUD',
  'BRL',
  'CAD',
  'CNY',
  'CZK',
  'HKD',
  'HUF',
  'IDR',
  'ILS',
  'INR',
  'JPY',
  'KRW',
  'MXN',
  'MYR',
  'NZD',
  'PHP',
  'PLN',
  'RON',
  'SGD',
  'THB',
  'TRY',
  'ZAR',
];

String detectedCurrency(Locale locale) {
  final detected = NumberFormat.simpleCurrency(
    locale: locale.toString(),
  ).currencyName;
  return supportedExchangeCurrencies.contains(detected) ? detected! : 'EUR';
}

enum AccountThemeMode {
  system('SYSTEM', 'System'),
  light('LIGHT', 'Light'),
  dark('DARK', 'Dark');

  const AccountThemeMode(this.apiValue, this.label);
  final String apiValue;
  final String label;

  ThemeMode get themeMode => switch (this) {
    AccountThemeMode.system => ThemeMode.system,
    AccountThemeMode.light => ThemeMode.light,
    AccountThemeMode.dark => ThemeMode.dark,
  };

  static AccountThemeMode parse(String? value) =>
      values.where((item) => item.apiValue == value).firstOrNull ?? system;
}

enum MeasurementSystem {
  metric('METRIC', 'Metric', 'cm', '°C', 'kg'),
  imperial('IMPERIAL', 'Imperial', 'in', '°F', 'lb');

  const MeasurementSystem(
    this.apiValue,
    this.label,
    this.lengthSymbol,
    this.temperatureSymbol,
    this.weightSymbol,
  );
  final String apiValue;
  final String label;
  final String lengthSymbol;
  final String temperatureSymbol;
  final String weightSymbol;

  static MeasurementSystem parse(String? value) =>
      values.where((item) => item.apiValue == value).firstOrNull ?? metric;
}

enum PrivacyAudience {
  everyone('EVERYONE', 'Everyone'),
  friends('FRIENDS', 'Friends'),
  friendsOfFriends('FRIENDS_OF_FRIENDS', 'Friends of friends'),
  noOne('NO_ONE', 'No one');

  const PrivacyAudience(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static PrivacyAudience parse(String? value) =>
      values.where((item) => item.apiValue == value).firstOrNull ?? everyone;
}

class AccountSettingsDto {
  const AccountSettingsDto({
    this.themeMode = AccountThemeMode.system,
    this.measurementSystem = MeasurementSystem.metric,
    this.languageTag = 'en',
    this.preferredCurrency = 'AUTO',
    this.discoverability = PrivacyAudience.everyone,
    this.friendRequests = PrivacyAudience.everyone,
    this.messages = PrivacyAudience.everyone,
    this.notifyDirectMessages = true,
    this.notifyMessageRequests = true,
    this.notifyFriendRequests = true,
    this.notifyGroupActivity = true,
  });

  final AccountThemeMode themeMode;
  final MeasurementSystem measurementSystem;
  final String languageTag;
  final String preferredCurrency;
  final PrivacyAudience discoverability;
  final PrivacyAudience friendRequests;
  final PrivacyAudience messages;
  final bool notifyDirectMessages;
  final bool notifyMessageRequests;
  final bool notifyFriendRequests;
  final bool notifyGroupActivity;

  factory AccountSettingsDto.fromJson(Map<String, dynamic> json) {
    return AccountSettingsDto(
      themeMode: AccountThemeMode.parse(json['themeMode'] as String?),
      measurementSystem: MeasurementSystem.parse(
        json['measurementSystem'] as String?,
      ),
      languageTag: json['languageTag'] as String? ?? 'en',
      preferredCurrency: json['preferredCurrency'] as String? ?? 'AUTO',
      discoverability: PrivacyAudience.parse(
        json['discoverability'] as String?,
      ),
      friendRequests: PrivacyAudience.parse(json['friendRequests'] as String?),
      messages: PrivacyAudience.parse(json['messages'] as String?),
      notifyDirectMessages: json['notifyDirectMessages'] as bool? ?? true,
      notifyMessageRequests: json['notifyMessageRequests'] as bool? ?? true,
      notifyFriendRequests: json['notifyFriendRequests'] as bool? ?? true,
      notifyGroupActivity: json['notifyGroupActivity'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.apiValue,
    'measurementSystem': measurementSystem.apiValue,
    'languageTag': languageTag,
    'preferredCurrency': preferredCurrency,
    'discoverability': discoverability.apiValue,
    'friendRequests': friendRequests.apiValue,
    'messages': messages.apiValue,
    'notifyDirectMessages': notifyDirectMessages,
    'notifyMessageRequests': notifyMessageRequests,
    'notifyFriendRequests': notifyFriendRequests,
    'notifyGroupActivity': notifyGroupActivity,
  };

  AccountSettingsDto copyWith({
    AccountThemeMode? themeMode,
    MeasurementSystem? measurementSystem,
    String? languageTag,
    String? preferredCurrency,
    PrivacyAudience? discoverability,
    PrivacyAudience? friendRequests,
    PrivacyAudience? messages,
    bool? notifyDirectMessages,
    bool? notifyMessageRequests,
    bool? notifyFriendRequests,
    bool? notifyGroupActivity,
  }) {
    return AccountSettingsDto(
      themeMode: themeMode ?? this.themeMode,
      measurementSystem: measurementSystem ?? this.measurementSystem,
      languageTag: languageTag ?? this.languageTag,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      discoverability: discoverability ?? this.discoverability,
      friendRequests: friendRequests ?? this.friendRequests,
      messages: messages ?? this.messages,
      notifyDirectMessages: notifyDirectMessages ?? this.notifyDirectMessages,
      notifyMessageRequests:
          notifyMessageRequests ?? this.notifyMessageRequests,
      notifyFriendRequests: notifyFriendRequests ?? this.notifyFriendRequests,
      notifyGroupActivity: notifyGroupActivity ?? this.notifyGroupActivity,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

import 'dart:convert';
import 'dart:io';

import 'package:ceramic_app/l10n/app_localizations.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every ARB is complete and placeholder metadata is present', () {
    final files = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.arb'))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));
    expect(files.map((file) => file.path), hasLength(greaterThanOrEqualTo(2)));

    final documents = {
      for (final file in files)
        file.path: jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    };
    final template = documents.entries
        .singleWhere((entry) => entry.key.endsWith('app_en.arb'))
        .value;
    final templateKeys = _messageKeys(template);

    for (final entry in documents.entries) {
      final document = entry.value;
      expect(
        document['@@locale'],
        isA<String>().having((value) => value.isNotEmpty, 'non-empty', isTrue),
        reason: entry.key,
      );
      expect(
        document['languageName'],
        isA<String>().having((value) => value.trim().isNotEmpty, 'name', isTrue),
        reason: entry.key,
      );
      expect(_messageKeys(document), templateKeys, reason: entry.key);

      for (final key in templateKeys) {
        final value = document[key];
        expect(value, isA<String>(), reason: '${entry.key}: $key');
        if ((value! as String).contains('{')) {
          final metadata = document['@$key'];
          expect(metadata, isA<Map<String, dynamic>>(), reason: entry.key);
          expect(
            (metadata as Map<String, dynamic>)['placeholders'],
            isA<Map<String, dynamic>>(),
            reason: '${entry.key}: $key',
          );
        }
      }
    }
  });

  test('generated English and Danish messages load and format ICU plurals', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final danish = await AppLocalizations.delegate.load(const Locale('da'));

    expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    expect(AppLocalizations.supportedLocales, contains(const Locale('da')));
    expect(english.languageName, 'English');
    expect(danish.languageName, 'Dansk');
    expect(english.pieceCount(1), '1 piece');
    expect(english.pieceCount(3), '3 pieces');
    expect(danish.pieceCount(1), '1 emne');
    expect(danish.pieceCount(3), '3 emner');

    final danishMaterial =
        await GlobalMaterialLocalizations.delegate.load(const Locale('da'));
    expect(danishMaterial.cancelButtonLabel, 'Annuller');
  });

  test('six canonical stages localize and unknown server stages pass through',
      () async {
    final danish = await AppLocalizations.delegate.load(const Locale('da'));

    expect(localizedStageName(danish, 'Ideas'), 'Idéer');
    expect(localizedStageName(danish, 'Thrown'), 'Drejet');
    expect(localizedStageName(danish, 'Trimmed'), 'Afdrejet');
    expect(localizedStageName(danish, 'Bisqued'), 'Forglødnet');
    expect(localizedStageName(danish, 'Glazed'), 'Glaseret');
    expect(localizedStageName(danish, 'Finished'), 'Færdig');
    expect(localizedStageName(danish, 'Custom studio stage'), 'Custom studio stage');
  });
}

Set<String> _messageKeys(Map<String, dynamic> document) => document.keys
    .where((key) => !key.startsWith('@'))
    .toSet();

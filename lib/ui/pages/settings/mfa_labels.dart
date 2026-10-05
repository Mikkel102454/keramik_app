import 'package:flutter/widgets.dart';

/// MFA is available in the same two supported languages as the app.
String mfaText(BuildContext context, String english, String danish) =>
    Localizations.localeOf(context).languageCode == 'da' ? danish : english;

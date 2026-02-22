import 'package:url_launcher/url_launcher.dart';

Future<void> openWebPage(String url) async {
  final Uri uri = Uri.parse(url);

  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Could not open $url';
  }
}
import 'package:ceramic_app/config/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug API default targets the Android emulator host bridge', () {
    expect(AppConstants.api.apiDomain, 'http://10.0.2.2:8080');
  });
}

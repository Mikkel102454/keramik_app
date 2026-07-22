import 'package:ceramic_app/cubits/authentication/authentication_cubit.dart';
import 'package:ceramic_app/utils/web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forced password reset directs the member to the website', () {
    const exception = ApiException(
      'Change your temporary password on the website before signing in',
      statusCode: 403,
      code: 'PASSWORD_CHANGE_REQUIRED',
    );

    expect(
      authenticationErrorMessage(exception),
      'Change your temporary password on the Keramik website before signing in.',
    );
  });

  test('invalid credentials remain distinct from server failures', () {
    expect(
      authenticationErrorMessage(
        const ApiException('Invalid', statusCode: 401, code: 'UNAUTHORIZED'),
      ),
      'Invalid credentials',
    );
    expect(
      authenticationErrorMessage(
        const ApiException('Unavailable', statusCode: 500),
      ),
      'Server error',
    );
  });
}

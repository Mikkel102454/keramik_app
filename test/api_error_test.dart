import 'package:ceramic_app/utils/web.dart';
import 'package:flutter_test/flutter_test.dart';

class _Response {
  _Response(this.statusCode, this.data);
  final int statusCode;
  final dynamic data;
}

void main() {
  test('successful envelope is accepted', () {
    expect(() => checkSuccess(_Response(200, {'success': true})), returnsNormally);
  });

  test('session expiry is a typed API error', () {
    expect(
      () => checkSuccess(_Response(401, {
        'success': false,
        'error': {'code': 'UNAUTHORIZED', 'message': 'Unauthorized'},
      })),
      throwsA(isA<ApiException>().having((error) => error.statusCode, 'statusCode', 401)),
    );
  });

  for (final scenario in <(int, String)>[
    (400, 'VALIDATION_ERROR'),
    (401, 'UNAUTHORIZED'),
    (404, 'NOT_FOUND'),
    (409, 'CONFLICT'),
    (500, 'INTERNAL_ERROR'),
  ]) {
    test('${scenario.$2} envelope is parsed', () {
      expect(
        () => checkSuccess(_Response(scenario.$1, {
          'success': false,
          'error': {'code': scenario.$2, 'message': 'Safe message'},
        })),
        throwsA(isA<ApiException>()
            .having((error) => error.code, 'code', scenario.$2)
            .having((error) => error.message, 'message', 'Safe message')),
      );
    });
  }

  test('server error message is preserved', () {
    expect(
      () => checkSuccess(_Response(409, {
        'success': false,
        'error': {'message': 'Already exists'},
      })),
      throwsA(isA<ApiException>().having((error) => error.message, 'message', 'Already exists')),
    );
  });
}

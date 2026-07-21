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
      () => checkSuccess(_Response(401, null)),
      throwsA(isA<ApiException>().having((error) => error.statusCode, 'statusCode', 401)),
    );
  });

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

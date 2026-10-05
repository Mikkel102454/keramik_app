import 'package:clay_dock/api/api_client.dart';
import 'package:clay_dock/objects/purchase_options.dart';
import 'package:clay_dock/utils/web.dart';
import 'package:dio/dio.dart';

class PurchaseRepository {
  PurchaseRepository({Dio? dio}) : _dio = dio;
  final Dio? _dio;
  Dio get dio => _dio ?? ApiClient.dio;
  Options get _options => Options(
    sendTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Cache-Control': 'no-cache'},
  );
  Future<PurchaseOptions> load(String country) async {
    final response = await dio.get(
      '/api/billing/purchase-options',
      queryParameters: {'country': country},
      options: _options,
    );
    checkSuccess(response);
    return PurchaseOptions.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  Future<String> start(
    PurchaseOptions policy,
    PurchaseRoute route,
    String country,
    String? product,
    String? basePlan,
  ) async {
    final response = await dio.post(
      '/api/billing/start',
      data: {
        'revision': policy.revision,
        'mode': route.mode,
        'country': country,
        'productId': product,
        'basePlanId': basePlan,
      },
      options: _options,
    );
    checkSuccess(response);
    return response.data['data']['operationId'] as String;
  }

  Future<String> external(
    String operation,
    String token,
    String country,
  ) async {
    final response = await dio.post(
      '/api/billing/external/prepare',
      data: {
        'operationId': operation,
        'reportingToken': token,
        'country': country,
      },
      options: _options,
    );
    checkSuccess(response);
    return response.data['data'] as String;
  }

  Future<void> verify(String token) async {
    final response = await dio.post(
      '/api/billing/play/verify',
      data: {'purchaseToken': token},
      options: _options,
    );
    checkSuccess(response);
  }

  Future<void> release(String operation) async {
    final response = await dio.post(
      '/api/billing/release',
      data: {'operationId': operation},
      options: _options,
    );
    checkSuccess(response);
  }
}

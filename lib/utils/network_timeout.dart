import 'package:dio/dio.dart';

/// A transport timeout says nothing about whether a mutation was committed.
/// Keep drafts and logical retry IDs; only retry when the user requests it.
bool isNetworkTimeout(Object error) =>
    error is DioException &&
    (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout);

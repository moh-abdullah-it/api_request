import 'package:dio/dio.dart';

class ApiRequestError implements Exception {
  /// Request info.
  late RequestOptions? requestOptions;

  late int? statusCode;

  /// Response info, it may be `null` if the request can't reach to
  /// the http server, for example, occurring a dns error, network is not available.
  late Response? response;

  /// The original error/exception object; It's usually not null when `type`
  /// is DioErrorType.DEFAULT
  dynamic error;
  Map<String, dynamic>? errors;

  String? message;

  StackTrace? stackTrace;

  @override
  String toString() {
    var msg = 'ApiRequest Error: $message';
    if (stackTrace != null) {
      msg += '\n$stackTrace';
    }
    return msg;
  }

  ApiRequestError(dynamic apiError) {
    if (apiError is DioError) {
      this.requestOptions = apiError.requestOptions;
      this.response = apiError.response;
      this.error = apiError.error;
      this.statusCode = apiError.response?.statusCode;
      message = (error?.toString() ?? '');
      if (this.response?.data is Map) {
        if (this.response?.data['errors'] is Map) {
          this.errors = this.response?.data['errors'];
        }
        if (this.response?.data['message'] != null) {
          message = this.response?.data['message'];
        }
      }
    } else if (apiError is Error) {
      this.message = apiError.toString();
      this.stackTrace = apiError.stackTrace;
      error = apiError;
    } else {
      throw Exception('Unknown Error');
    }
  }
}

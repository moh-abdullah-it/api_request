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
  late dynamic error;
  Map<String, dynamic>? errors;

  String? message;

  @override
  String toString() {
    var msg = 'ApiRequest Error: $message';
    return msg;
  }

  ApiRequestError(DioError _dioError) {
    this.requestOptions = _dioError.requestOptions;
    this.response = _dioError.response;
    this.error = _dioError.error;
    this.statusCode = _dioError.response?.statusCode;
    message = (error?.toString() ?? '');
    if (this.response?.data is Map) {
      if (this.response?.data['errors'] is Map) {
        this.errors = this.response?.data['errors'];
      }
      if (this.response?.data['message'] != null) {
        message = this.response?.data['message'];
      }
    }
  }
}

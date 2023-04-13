import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

// Action Requests Types
enum ActionErrorType { Api, Response, Unknown }

class ActionRequestError implements Exception {
  /// Request info.
  late RequestOptions? requestOptions;

  // Action Request Type
  ActionErrorType? type;

  late int? statusCode;

  /// Response info, it may be `null` if the request can't reach to
  /// the http server, for example, occurring a dns error, network is not available.
  Response? response;

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

  ActionRequestError(dynamic apiError, {Response? res}) {
    if (apiError is DioError) {
      this.requestOptions = apiError.requestOptions;
      this.response = apiError.response;
      this.error = apiError.error;
      this.statusCode = apiError.response?.statusCode;
      message = apiError.message;
      this.type = ActionErrorType.Api;
      print(
          "🛑️ 🛑️ 🛑️ 🛑️ 🛑️ 🛑 🛑️ 🛑 Start Action Request Error 🛑 🛑 🛑 🛑 🛑 🛑 🛑 🛑️ \n"
          "message: ${this.message}\n"
          "statusCode: ${this.statusCode}\n"
          "url: ${this.requestOptions?.uri.toString()}\n"
          "method: ${this.requestOptions?.method}\n"
          "type: ${this.type.toString().split('.').last.toString()}\n"
          "response: ${this.response}\n"
          "----------------- End Action Request Error -------------------");
      if (this.response?.data is Map) {
        if (this.response?.data['errors'] is Map) {
          this.errors = this.response?.data['errors'];
        }
        if (this.response?.data['message'] != null) {
          message = this.response?.data['message'];
        }
      }
    } else if (apiError is Error) {
      this.type = ActionErrorType.Response;
      this.message = apiError.toString();
      this.stackTrace = apiError.stackTrace;
      error = apiError;
      print(
          "⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ Start Action Request Error ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ \n"
          "message: ${this.message}\n"
          "statusCode: ${res?.statusCode}\n"
          "url: ${res?.requestOptions.uri.toString()}\n"
          "method: ${res?.requestOptions.method}\n"
          "type: ${this.type.toString().split('.').last.toString()}: ${apiError.runtimeType}\n"
          "stackTrace: ${this.stackTrace}\n"
          "response: ${res?.data}");
    } else {
      this.type = ActionErrorType.Unknown;
      print('Error: $apiError');
      debugPrintStack(stackTrace: this.stackTrace, label: "Unknown Error");
      throw Exception('Unknown Error');
    }
  }
}

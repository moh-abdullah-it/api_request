import 'package:api_request/src/api_request_error.dart';
import 'package:dio/dio.dart';

import '../actions/request_action.dart';

class ErrorInterceptor extends Interceptor {
  String _tag = 'onError_';
  Function obError;

  ErrorInterceptor(RequestAction action, this.obError) {
    this._tag += action.runtimeType.toString();
  }

  @override
  void onError(DioError error, ErrorInterceptorHandler handler) {
    this.obError(ApiRequestError(error));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorInterceptor &&
          runtimeType == other.runtimeType &&
          _tag == other._tag;

  @override
  int get hashCode => _tag.hashCode;
}

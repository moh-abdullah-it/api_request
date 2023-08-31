import 'package:dio/dio.dart';

import '../../api_request.dart';

class UnauthenticatedInterceptor extends ApiInterceptor {
  final String _tag = 'unauthenticated';
  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    if (error.response?.statusCode == 401) {
      ApiRequestOptions.instance?.unauthenticated!();
    }
    super.onError(error, handler);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnauthenticatedInterceptor &&
          runtimeType == other.runtimeType &&
          _tag == other._tag;

  @override
  int get hashCode => _tag.hashCode;
}

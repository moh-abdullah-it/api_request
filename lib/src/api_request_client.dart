import 'package:api_request/src/interceptors/token_interceptor.dart';
import 'package:api_request/src/interceptors/unauthenticated_interceptor.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api_request.dart';

class RequestClient extends DioMixin implements Dio {
  static RequestClient? _instance;

  RequestClient._() {
    intConfig();
  }

  static RequestClient? get instance {
    if (_instance == null) {
      _instance = RequestClient._();
    }
    return _instance;
  }

  intConfig() {
    options = BaseOptions(
      baseUrl: ApiRequestOptions.instance!.baseUrl,
      queryParameters: ApiRequestOptions.instance?.defaultQueryParameters ?? {},
    );
    httpClientAdapter = DefaultHttpClientAdapter();
    if (!kReleaseMode) {
      interceptors.add(LogInterceptor(responseBody: true));
    }
    options.headers.addAll({Headers.acceptHeader: Headers.jsonContentType});
    if (ApiRequestOptions.instance != null) {
      if (ApiRequestOptions.instance?.unauthenticated != null) {
        addInterceptorOnce(UnauthenticatedInterceptor());
      }
    }
  }

  configAuth(bool authRequired) {
    bool hasInterceptor = interceptors.contains(TokenInterceptor());
    if (!authRequired && hasInterceptor) {
      interceptors.remove(TokenInterceptor());
    } else if (authRequired) {
      addInterceptorOnce(TokenInterceptor());
    }
  }

  addInterceptorOnce(Interceptor interceptor) {
    if (!interceptors.contains(interceptor)) {
      interceptors.add(interceptor);
    }
  }
}

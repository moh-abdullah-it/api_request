import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_request_options.dart';

abstract class ApiRequest {
  Map<String, dynamic> toMap();
}

abstract class RequestAction<T, R extends ApiRequest> {
  String get path;
  Future<T> execute({R? request});
  bool get authRequired;
  String? _token;

  final Dio _dio = Dio();

  RequestAction() {
    if (!kReleaseMode) {
      _dio.interceptors.add(LogInterceptor(responseBody: true));
    }
    _dio.options.headers.addAll({"Accept": "application/json"});
    if (ApiRequestOptions.instance != null) {
      _dio.options.baseUrl = ApiRequestOptions.instance!.baseUrl;
      if (ApiRequestOptions.instance?.unauthenticated != null) {
        _dio.interceptors.add(InterceptorsWrapper(onError: (e, __) {
          if (e.response?.statusCode == 401) {
            ApiRequestOptions.instance?.unauthenticated!();
          }
        }));
      }
      if (ApiRequestOptions.instance?.defaultQueryParameters != null) {
        _dio.options.queryParameters =
            ApiRequestOptions.instance!.defaultQueryParameters;
      }
      if (authRequired) {
        addToken();
      }
    }
  }
  Dio get dio => _dio;

  addToken() async {
    if (ApiRequestOptions.instance?.token != null) {
      _token = ApiRequestOptions.instance?.token;
    }
    if (ApiRequestOptions.instance?.getToken != null) {
      _token = ApiRequestOptions.instance?.getToken!();
    }
    if (ApiRequestOptions.instance?.getAsyncToken != null) {
      _token = await ApiRequestOptions.instance?.getAsyncToken!();
    }
    if (_token != null) {
      _dio.options.headers.addAll(
          {"Authorization": "Bearer ${ApiRequestOptions.instance?.token}"});
    }
  }

  Future<Map<String, dynamic>> get([R? request]) async {
    var response = await dio.get(path, queryParameters: request?.toMap() ?? {});
    return response.data;
  }

  Future<Map<String, dynamic>> post([R? request]) async {
    var response = await dio.post(path, data: request?.toMap() ?? {});
    return response.data;
  }

  Future<Map<String, dynamic>> put([R? request]) async {
    var response = await dio.put(path, data: request?.toMap() ?? {});
    return response.data;
  }

  Future<Map<String, dynamic>> delete([R? request]) async {
    var response = await dio.delete(path, data: request?.toMap() ?? {});
    return response.data;
  }
}

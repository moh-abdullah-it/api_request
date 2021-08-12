import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_request_options.dart';

enum ContentDataType { formData, bodyData }
mixin ApiRequest {
  ContentDataType? get contentDataType => null;
  Map<String, dynamic> toMap();
}

abstract class RequestAction<T, R extends ApiRequest> {
  String get path;
  late String _dynamicPath;
  Future<T> execute({R? request});
  bool get authRequired;
  String? _token;
  var _dataMap;

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

  Future<dynamic> get([R? request]) async {
    var response = await handleRequest(request).dio.get(
          _dynamicPath,
          queryParameters: _dataMap,
        );
    return response.data;
  }

  Future<dynamic> post([R? request]) async {
    var response = await handleRequest(request).dio.post(
          _dynamicPath,
          data: _dataMap,
        );
    return response.data;
  }

  Future<dynamic> put([R? request]) async {
    var response = await handleRequest(request).dio.put(
          _dynamicPath,
          data: _dataMap,
        );
    return response.data;
  }

  Future<dynamic> delete([R? request]) async {
    var response = await handleRequest(request).dio.delete(
          _dynamicPath,
          data: _dataMap,
        );
    return response.data;
  }

  RequestAction handleRequest(R? request) {
    Map<String, dynamic> newData =
        handleDynamicPathWithData(path, request?.toMap() ?? {});
    this._dynamicPath = newData['path'];
    this._dataMap = newData['data'];
    if (request?.contentDataType == ContentDataType.formData) {
      this._dataMap = FormData.fromMap(newData['data']);
    } else {
      this._dataMap = newData['data'];
    }
    return this;
  }

  Map<String, dynamic> handleDynamicPathWithData(
      String path, Map<String, dynamic> map) {
    Map<String, dynamic> newData = {};
    map.keys.forEach((key) {
      if (path.contains('{$key}')) {
        path = path.replaceFirst('{$key}', map[key].toString());
      } else {
        newData[key] = map[key];
      }
    });
    return {'path': path, 'data': newData};
  }
}

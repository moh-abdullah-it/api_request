import 'package:dio/dio.dart';

import 'api_request.dart';
import 'api_request_client.dart';

enum RequestMethod { GET, POST, PUT, DELETE }

typedef ResponseBuilder<T> = T Function(dynamic);

abstract class RequestAction<T, R extends ApiRequest?> {
  final RequestClient? _requestClient = RequestClient.instance;
  R? request;

  bool get authRequired;

  String get path;

  RequestMethod get method;

  late String _dynamicPath;

  ResponseBuilder<T> get responseBuilder;

  Future execute() async {
    T _response;
    switch (this.method) {
      case RequestMethod.GET:
        _response = responseBuilder(await get());
        break;
      case RequestMethod.POST:
        _response = responseBuilder(await post());
        break;
      case RequestMethod.PUT:
        _response = responseBuilder(await put());
        break;
      case RequestMethod.DELETE:
        _response = responseBuilder(await delete());
        break;
    }
    return _response;
  }

  var _dataMap;

  RequestAction([this.request]) {
    _requestClient?.configAuth(authRequired);
    handleRequest(this.request);
  }

  Future<dynamic> get() async {
    var response = await _requestClient?.get(
      _dynamicPath,
      queryParameters: _dataMap,
    );
    return response?.data;
  }

  Future<dynamic> post() async {
    var response = await _requestClient?.post(
      _dynamicPath,
      data: _dataMap,
    );
    return response?.data;
  }

  Future<dynamic> put() async {
    var response = await _requestClient?.put(
      _dynamicPath,
      data: _dataMap,
    );
    return response?.data;
  }

  Future<dynamic> delete() async {
    var response = await _requestClient?.delete(
      _dynamicPath,
      data: _dataMap,
    );
    return response?.data;
  }

  RequestAction handleRequest(R? request) {
    Map<String, dynamic> newData =
        handleDynamicPathWithData(path, request?.toMap() ?? {});
    this._dynamicPath = newData['path'];
    this._dataMap = newData['data'];
    if (request?.contentDataType == ContentDataType.formData &&
        method != RequestMethod.GET) {
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

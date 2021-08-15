import 'dart:async';

import 'package:api_request/src/interceptors/error_interceptor.dart';
import 'package:dio/dio.dart';

import 'api_request.dart';
import 'api_request_client.dart';
import 'api_request_error.dart';

enum RequestMethod { GET, POST, PUT, DELETE }

typedef ResponseBuilder<T> = T Function(dynamic);

abstract class RequestAction<T, R extends ApiRequest> {
  final RequestClient? _requestClient = RequestClient.instance;
  final StreamController<T> _streamController = StreamController<T>();
  R? request;

  bool get authRequired;

  String get path;

  RequestMethod get method;

  late String _dynamicPath;

  ResponseBuilder<T> get responseBuilder;

  void onInit() {}

  void onStart() {}

  void onError(ApiRequestError error) {
    if (!_streamController.isClosed) {
      _streamController.sink.addError(error);
      _streamController.close();
    }
  }

  void onSuccess(T response) {
    _streamController.sink.add(response);
    _streamController.close();
  }

  StreamSubscription<T> onChange(
      {Function(T response)? onSuccess, Function(Object error)? onError}) {
    return _streamController.stream
        .listen(onSuccess, cancelOnError: true, onError: onError);
  }

  Future execute() async {
    this.onStart();
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
    this.onSuccess(_response);
    return _response;
  }

  void onQueue() {
    switch (this.method) {
      case RequestMethod.GET:
        get().then((value) => this.onSuccess(responseBuilder(value)));
        break;
      case RequestMethod.POST:
        post().then((value) => this.onSuccess(responseBuilder(value)));
        break;
      case RequestMethod.PUT:
        put().then((value) => this.onSuccess(responseBuilder(value)));
        break;
      case RequestMethod.DELETE:
        delete().then((value) => this.onSuccess(responseBuilder(value)));
        break;
    }
  }

  var _dataMap;

  RequestAction(this.request) {
    this.onInit();
    _requestClient?.configAuth(authRequired);
    handleRequest(this.request);
    _requestClient?.addInterceptorOnce(ErrorInterceptor(this, this.onError));
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

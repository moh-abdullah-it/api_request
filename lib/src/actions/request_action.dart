import 'dart:async';

import 'package:api_request/src/interceptors/error_interceptor.dart';
import 'package:dio/dio.dart';

import '../api_request.dart';
import '../api_request_client.dart';
import '../api_request_error.dart';

enum RequestMethod { GET, POST, PUT, DELETE }

typedef ResponseBuilder<T> = T Function(dynamic);

abstract class RequestAction<T, R extends ApiRequest> {
  final RequestClient? _requestClient = RequestClient.instance;
  final StreamController<T> _streamController = StreamController<T>();
  Stream<T> get stream => _streamController.stream;
  R? request;
  ContentDataType? get contentDataType => null;

  bool get authRequired => false;

  String get path;

  RequestMethod get method;

  late String _dynamicPath;

  ResponseBuilder<T> get responseBuilder;

  Map<String, dynamic> get toMap => {};

  void onInit() {}

  void onStart() {}

  void onError(ApiRequestError error) {
    if (!_streamController.isClosed) {
      _streamController.sink.addError(error);
      this.dispose();
    }
  }

  void onSuccess(T response) {
    if (!_streamController.isClosed) {
      _streamController.sink.add(response);
      this.dispose();
    }
  }

  StreamSubscription<T> subscribe(
      {Function(T response)? onSuccess,
      Function()? onDone,
      Function(Object error)? onError}) {
    return stream.listen(onSuccess,
        cancelOnError: true, onError: onError, onDone: onDone);
  }

  Future<T> execute() async {
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
    _requestClient?.addInterceptorOnce(_errorInterceptor());
  }

  Future<dynamic> get() async {
    var response = await _requestClient?.dio.get(
      _dynamicPath,
      queryParameters: _dataMap,
    );
    return response?.data;
  }

  Future<dynamic> post() async {
    var response = await _requestClient?.dio.post(
      _dynamicPath,
      data: _dataMap,
    );
    return response?.data;
  }

  Future<dynamic> put() async {
    var response = await _requestClient?.dio.put(
      _dynamicPath,
      data: _dataMap,
    );
    return response?.data;
  }

  Future<dynamic> delete() async {
    var response = await _requestClient?.dio.delete(
      _dynamicPath,
      data: _dataMap,
    );
    return response?.data;
  }

  RequestAction handleRequest(R? request) {
    Map<String, dynamic> newData = handleDynamicPathWithData(
        path, toMap.isNotEmpty ? toMap : request?.toMap() ?? {});
    this._dynamicPath = newData['path'];
    this._dataMap = newData['data'];
    if ((this.contentDataType == ContentDataType.formData ||
            request?.contentDataType == ContentDataType.formData) &&
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

  ErrorInterceptor _errorInterceptor() {
    return ErrorInterceptor(this, this.onError);
  }

  void dispose() {
    if (!_streamController.isClosed) {
      _streamController.close();
    }
    _requestClient?.removeInterceptor(_errorInterceptor());
  }
}

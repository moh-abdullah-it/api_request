import 'dart:async';

import 'package:api_request/api_request.dart';
import 'package:dio/dio.dart';

import '../api_request.dart';
import '../api_request_client.dart';
import '../api_request_error.dart';
import '../utils/api_request_utils.dart';

enum RequestMethod { GET, POST, PUT, DELETE }

typedef ResponseBuilder<T> = T Function(dynamic);
typedef ErrorHandler = Function(ApiRequestError error);
typedef SuccessHandler<T> = Function(T? response);

abstract class RequestAction<T, R extends ApiRequest> {
  RequestAction(this.request) {
    this.onInit();
    _requestClient?.configAuth(authRequired);
    handleRequest(this.request);
    _performanceUtils?.init(this.runtimeType.toString(),
        ApiRequestOptions.instance!.baseUrl + _dynamicPath);
  }

  final RequestClient? _requestClient = RequestClient.instance;
  final ApiRequestPerformance? _performanceUtils =
      ApiRequestPerformance.instance;
  final StreamController<T?> _streamController = StreamController<T?>();

  Stream<T?> get stream => _streamController.stream;
  R? request;

  ContentDataType? get contentDataType => null;

  bool get authRequired => false;

  String get path;

  RequestMethod get method;

  late String _dynamicPath;

  ResponseBuilder<T> get responseBuilder;

  Map<String, dynamic> get toMap => {};

  var _dataMap;

  Function onInit = () => {};

  Function onStart = () => {};

  ErrorHandler onError = (error) => {};

  SuccessHandler<T> onSuccess = (response) => {};

  void _streamError(ApiRequestError error) {
    this.onError(error);
    if (this._streamController.isClosed) {
      _streamController.sink.addError(error);
      this.dispose();
    }
  }


  void _streamSuccess(T? response) {
    this.onSuccess(response);
    if (!_streamController.isClosed) {
      _streamController.sink.add(response);
      this.dispose();
    }
  }

  StreamSubscription<T?> subscribe(
      {Function(T? response)? onSuccess,
      Function()? onDone,
      Function(Object error)? onError}) {
    return stream.listen(onSuccess, onError: onError, onDone: onDone);
  }

  Future<T?> execute() async {
    return await _execute().catchError((error) {
      this._streamError(ApiRequestError(error));
    });
  }

  Future<T?> _execute() async {
    this.onStart();
    _performanceUtils?.startTrack();
    T? _response;
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
    _performanceUtils?.endTrack();
    this._streamSuccess(_response);
    return _response;
  }

  void onQueue() {
    _performanceUtils?.startTrack();
    this.onStart();
    Future<dynamic> _dynamicCall;
    switch (this.method) {
      case RequestMethod.GET:
        _dynamicCall = get();
        break;
      case RequestMethod.POST:
        _dynamicCall = post();
        break;
      case RequestMethod.PUT:
        _dynamicCall = put();
        break;
      case RequestMethod.DELETE:
        _dynamicCall = delete();
        break;
    }
    _dynamicCall
        .then((value) => this._streamSuccess(responseBuilder(value)))
        .catchError((error) => this._streamError(ApiRequestError(error)))
        .then((_) => _performanceUtils?.endTrack());
  }

  PerformanceReport? get performanceReport => _performanceUtils?.getReport();

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

  handleRequest(R? request) {
    Map<String, dynamic> newData = ApiRequestUtils.handleDynamicPathWithData(
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
  }

  void dispose() {
    if (!_streamController.isClosed) {
      _streamController.close();
    }
  }
}

import 'dart:async';

import 'package:api_request/api_request.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../api_request_error.dart';
import '../api_request_exception.dart';
import '../utils/api_request_utils.dart';

enum RequestMethod { GET, POST, PUT, DELETE }

typedef ResponseBuilder<T> = T Function(dynamic);
typedef ErrorHandler = Function(ApiRequestError error);
typedef SuccessHandler<T> = Function(T? response);

abstract class RequestAction<T, R extends ApiRequest> {
  RequestAction(this._request) {
    this.onInit();
    _requestClient?.configAuth(authRequired);
    _handleRequest(this._request);
    _performanceUtils?.init(this.runtimeType.toString(),
        ApiRequestOptions.instance!.baseUrl + _dynamicPath);
  }

  final RequestClient? _requestClient = RequestClient.instance;
  final ApiRequestPerformance? _performanceUtils =
      ApiRequestPerformance.instance;
  final StreamController<T?> _streamController = StreamController<T?>();

  Stream<T?> get stream => _streamController.stream;
  R? _request;

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
    if (ApiRequestOptions.instance!.onError != null) {
      ApiRequestOptions.instance!.onError!(error);
    }
    if (!this._streamController.isClosed) {
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

  RequestAction subscribe(
      {Function(T? response)? onSuccess,
      Function()? onDone,
      Function(Object error)? onError}) {
    stream.listen(onSuccess, onError: onError, onDone: onDone);
    return this;
  }

  Future<Either<ApiRequestException, T?>> run() async {
    Response? response;
    Either<ApiRequestException, T?>? toReturn;
    await _execute().then((value) {
      response = value;
    }).catchError((e) {
      toReturn = left(ApiRequestException(
          message: e.toString(), type: ApiExceptionType.custom));
    });

    if (response != null) {
      int statusCode = response?.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        toReturn = right(responseBuilder(response?.data));
      }
      if (statusCode >= 400 && statusCode < 500) {
        toReturn = left(ApiRequestException(
            message: response?.data?["message"]?.toString() ??
                response?.statusMessage ??
                "client_error",
            type: ApiExceptionType.client,
            errors: response?.data?["errors"],
            statusCode: response?.statusCode,
            statusMessage: response?.statusMessage));
      }
      if (statusCode >= 500) {
        toReturn = left(ApiRequestException(
            message: "${response?.statusCode} : ${response?.statusMessage}",
            type: ApiExceptionType.server,
            statusCode: statusCode,
            statusMessage: response?.statusMessage));
      }
    } else {
      toReturn = left(
          ApiRequestException(message: "error", type: ApiExceptionType.custom));
    }

    return toReturn!;
  }

  @Deprecated('''
    this is deprecated user run instead
''')
  Future<T?> execute() async {
    Response? res;
    await _execute().then((value) {
      res = value;
    }).catchError((error) {
      this._streamError(ApiRequestError(error));
    });
    return responseBuilder(res);
  }

  Future<Response?> _execute() async {
    this.onStart();
    _performanceUtils?.startTrack();
    Response? _response;
    switch (this.method) {
      case RequestMethod.GET:
        _response = await get();
        break;
      case RequestMethod.POST:
        _response = await post();
        break;
      case RequestMethod.PUT:
        _response = await put();
        break;
      case RequestMethod.DELETE:
        _response = await delete();
        break;
    }
    _performanceUtils?.endTrack();
    this._streamSuccess(responseBuilder(_response?.data));

    return _response;
  }

  @Deprecated('''
    this is deprecated use run instead
''')
  void onQueue() {
    _performanceUtils?.startTrack();
    this.onStart();
    Future<Response?> _dynamicCall;
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
        .then((value) => this._streamSuccess(responseBuilder(value?.data)))
        .catchError((error) => this._streamError(ApiRequestError(error)))
        .then((_) => _performanceUtils?.endTrack());
  }

  PerformanceReport? get performanceReport => _performanceUtils?.getReport();

  Future<Response?> get() async {
    var response = await _requestClient?.dio.get(
      _dynamicPath,
      queryParameters: _dataMap,
    );

    return response;
  }

  Future<Response?> post() async {
    var response = await _requestClient?.dio.post(
      _dynamicPath,
      data: _dataMap,
    );
    return response;
  }

  Future<Response?> put() async {
    var response = await _requestClient?.dio.put(
      _dynamicPath,
      data: _dataMap,
    );
    return response;
  }

  Future<Response?> delete() async {
    var response = await _requestClient?.dio.delete(
      _dynamicPath,
      data: _dataMap,
    );
    return response;
  }

  _handleRequest(R? request) {
    Map<String, dynamic> newData = ApiRequestUtils.handleDynamicPathWithData(
        path, toMap.isNotEmpty ? toMap : request?.toMap() ?? {});
    this._dynamicPath = newData['path'];
    this._dataMap = newData['data'];
    if ((this.contentDataType == ContentDataType.formData ||
            request?.contentDataType == ContentDataType.formData) &&
        method != RequestMethod.GET) {
      this._dataMap = FormData.fromMap(
          newData['data'], ApiRequestOptions.instance!.listFormat);
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

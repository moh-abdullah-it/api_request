import 'dart:async';

import 'package:api_request/api_request.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../utils/api_request_utils.dart';

enum RequestMethod { GET, POST, PUT, DELETE }

typedef ResponseBuilder<T> = T Function(dynamic);
typedef ErrorHandler<E> = Function(ActionRequestError<E> error);
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
  Function onDone = () => {};

  void _streamError(ActionRequestError error) {
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

  RequestAction listen(
      {Function? onStart,
      Function? onDone,
      SuccessHandler<T>? onSuccess,
      ErrorHandler? onError}) {
    if (onStart != null) {
      this.onStart = onStart;
    }
    if (onDone != null) {
      this.onDone = onDone;
    }
    if (onSuccess != null) {
      this.onSuccess = onSuccess;
    }
    if (onError != null) {
      this.onError = onError;
    }
    return this;
  }

  Future<Either<ActionRequestError?, T?>> execute() async {
    Response? response;
    ActionRequestError? apiRequestError;
    Either<ActionRequestError?, T?>? either;
    try {
      response = await _execute();
      try {
        either = right(responseBuilder(response?.data));
        this.onSuccess(responseBuilder(response?.data));
      } catch (e) {
        apiRequestError = ActionRequestError(e, res: response);
        either = left(apiRequestError);
      }
    } catch (e) {
      apiRequestError = ActionRequestError(e);
      either = left(apiRequestError);
    }
    if (either.isLeft() && apiRequestError != null) {
      this.onError(apiRequestError);
      if (ApiRequestOptions.instance!.onError != null) {
        ApiRequestOptions.instance!.onError!(apiRequestError);
      }
    }
    this.onDone();
    return either;
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
    //this._streamSuccess(responseBuilder(_response?.data));

    return _response;
  }

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
        .catchError((error) => this._streamError(ActionRequestError(error)))
        .then((_) => _performanceUtils?.endTrack());
  }

  PerformanceReport? get performanceReport => _performanceUtils?.getReport();

  Future<Response?> get() async {
    return await _requestClient?.dio.get(
      _dynamicPath,
      queryParameters: _dataMap,
    );
  }

  Future<Response?> post() async {
    return await _requestClient?.dio.post(
      _dynamicPath,
      data: _dataMap,
    );
  }

  Future<Response?> put() async {
    return await _requestClient?.dio.put(
      _dynamicPath,
      data: _dataMap,
    );
  }

  Future<Response?> delete() async {
    return await _requestClient?.dio.delete(
      _dynamicPath,
      data: _dataMap,
    );
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

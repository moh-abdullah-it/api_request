import 'dart:async';
import 'dart:developer';
import 'package:api_request/api_request.dart';
import 'package:dartz/dartz.dart';

import '../utils/api_request_utils.dart';

enum RequestMethod { GET, POST, PUT, DELETE }

typedef ResponseBuilder<T> = T Function(dynamic);
typedef ErrorHandler<E> = Function(ActionRequestError<E> error);
typedef SuccessHandler<T> = Function(T? response);

abstract class RequestAction<T, R extends ApiRequest> {
  RequestAction(this._request) {
    this.onInit();
    _requestClient?.configAuth(authRequired);
  }

  final RequestClient? _requestClient = RequestClient.instance;
  final ApiRequestPerformance? _performanceUtils =
      ApiRequestPerformance.instance;
  final StreamController<T?> _streamController = StreamController<T?>();

  TestResponse? _testResponse;

  Stream<T?> get stream => _streamController.stream;
  R? _request;

  ContentDataType? get contentDataType => null;

  bool get authRequired => false;

  bool get disableGlobalOnError => false;

  String get path;

  RequestMethod get method;

  late String _dynamicPath;

  ResponseBuilder<T> get responseBuilder;

  Map<String, dynamic> get toMap => {};

  var _dataMap;

  Function onInit = () => {};

  Function onStart = () => {};

  Map<String, dynamic> _data = {};
  Map<String, dynamic> _query = {};

  ErrorHandler onError = (error) => {};
  SuccessHandler<T> onSuccess = (response) => {};
  Function onDone = () => {};
  Map<String, dynamic> _headers = {};

  void _streamError(ActionRequestError error) {
    this.onError(error);
    if (ApiRequestOptions.instance!.onError != null && !disableGlobalOnError) {
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

  RequestAction test(TestResponse testResponse) {
    this._testResponse = testResponse;
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

  Future<Either<ActionRequestError?, T?>?> execute() async {
    Response? response;
    ActionRequestError? apiRequestError;
    Either<ActionRequestError?, T?>? either;
    log('${authRequired} -- ${await ApiRequestOptions.instance?.getTokenString()}');
    if (authRequired == false ||
        (await ApiRequestOptions.instance?.getTokenString()) != null) {
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
        if (ApiRequestOptions.instance!.onError != null &&
            !disableGlobalOnError) {
          ApiRequestOptions.instance!.onError!(apiRequestError);
        }
      }
      this.onDone();
      return either;
    } else {
      log('You Need To Login to Request This action: ${this.runtimeType}');
    }
    return null;
  }

  Future<Response?> _execute() async {
    _handleRequest(this._request);
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
    _handleRequest(this._request);
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
    _query.addAll(Map.of(_dataMap));
    if (_testResponse != null) {
      return await _buildTestResponse("GET");
    }

    return await _requestClient?.dio.get(_dynamicPath,
        queryParameters: _query, options: Options(headers: _headers));
  }

  Future<Response?> post() async {
    if (_testResponse != null) {
      return await _buildTestResponse("POST");
    }
    return await _requestClient?.dio.post(_dynamicPath,
        data: _dataMap,
        queryParameters: _query,
        options: Options(headers: _headers));
  }

  Future<Response?> put() async {
    if (_testResponse != null) {
      return await _buildTestResponse("PUT");
    }
    return await _requestClient?.dio.put(_dynamicPath,
        data: _dataMap,
        queryParameters: _query,
        options: Options(headers: _headers));
  }

  Future<Response?> delete() async {
    if (_testResponse != null) {
      return await _buildTestResponse("DELETE");
    }
    return await _requestClient?.dio.delete(_dynamicPath,
        data: _dataMap,
        queryParameters: _query,
        options: Options(headers: _headers));
  }

  _handleRequest(R? request) {
    Map<String, dynamic> mapData =
        Map.of(toMap.isNotEmpty ? toMap : request?.toMap() ?? {});
    mapData.addAll(_data);
    Map<String, dynamic> newData =
        ApiRequestUtils.handleDynamicPathWithData(path, mapData);
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
    _performanceUtils?.init(this.runtimeType.toString(),
        ApiRequestOptions.instance!.baseUrl + _dynamicPath);
  }

  void dispose() {
    if (!_streamController.isClosed) {
      _streamController.close();
    }
  }

  RequestAction where(String key, dynamic value) {
    _data[key] = value;
    return this;
  }

  RequestAction whereMap(Map<String, dynamic> map) {
    _data.addAll(Map.of(map));
    return this;
  }

  RequestAction whereQuery(String key, dynamic value) {
    _query[key] = value;
    return this;
  }

  RequestAction whereMapQuery(Map<String, dynamic> map) {
    _query.addAll(Map.of(map));
    return this;
  }

  RequestAction withHeaders(Map<String, dynamic> headers) {
    _headers.addAll(Map.of(headers));
    return this;
  }

  RequestAction withHeader(String key, dynamic value) {
    _headers[key] = value;
    return this;
  }

  Future<Response?> _buildTestResponse(String method) async {
    await Future.delayed((Duration(seconds: 1)));
    RequestOptions options = RequestOptions(
      method: "$method",
      path: _dynamicPath,
      headers: _headers,
      queryParameters: _query,
      data: _dataMap,
    );
    if ((_testResponse?.statusCode ?? 300) >= 300) {
      throw DioException.badResponse(
        statusCode: _testResponse?.statusCode ?? 0,
        requestOptions: options,
        response: Response(
            statusCode: _testResponse?.statusCode,
            requestOptions: options,
            data: _testResponse?.data),
      );
    }
    return Response(
        statusCode: _testResponse?.statusCode,
        requestOptions: options,
        data: _testResponse?.data);
  }
}

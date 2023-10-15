import 'package:dartz/dartz.dart';

import '../api_request.dart';
import 'utils/api_request_utils.dart';

class SimpleApiRequest {
  static RequestClient? _requestClient = RequestClient.instance;
  static ResponseBuilder? responseBuilder;

  SimpleApiRequest._([withAuth = false]) {
    _requestClient?.configAuth(withAuth);
  }

  factory SimpleApiRequest.init() {
    return SimpleApiRequest._();
  }

  factory SimpleApiRequest.withAuth() {
    return SimpleApiRequest._(true);
  }

  factory SimpleApiRequest.withBuilder(ResponseBuilder builder,
      {bool withAuth = false}) {
    responseBuilder = builder;
    return SimpleApiRequest._(withAuth);
  }

  Future<Either<ActionRequestError, T?>?> get<T>(String path,
      {Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onReceiveProgress}) async {
    var handler =
        _handleRequest(path, data: queryParameters, isFormData: false);
    try {
      Response? response = await _requestClient?.dio.get(handler['path'],
          queryParameters: handler['data'],
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress);
      return _handleResponse(response: response);
    } catch (e) {
      return _handleError(error: e);
    }
  }

  Future<Either<ActionRequestError, T?>?> post<T>(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress,
      ResponseBuilder<T>? builder}) async {
    var handler = _handleRequest(path, data: data);
    try {
      Response? response = await _requestClient?.dio.post(handler['path'],
          data: handler['data'],
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress);
      return _handleResponse(response: response);
    } catch (e) {
      return _handleError(error: e);
    }
  }

  Future<Either<ActionRequestError, T?>?> put<T>(String path,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress,
      ResponseBuilder<T>? builder}) async {
    var handler = _handleRequest(path, data: data);
    try {
      Response? response = await _requestClient?.dio.put(handler['path'],
          data: handler['data'],
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress);
      return _handleResponse(response: response);
    } catch (e) {
      return _handleError(error: e);
    }
  }

  Future<Either<ActionRequestError, T?>?> delete<T>(String path,
      {data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ResponseBuilder<T>? builder}) async {
    var handler = _handleRequest(path, data: data);
    try {
      Response? response = await _requestClient?.dio.delete(handler['path'],
          data: handler['data'],
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);
      return _handleResponse(response: response);
    } catch (e) {
      return _handleError(error: e);
    }
  }

  Future<Response?> download(
    String path,
    savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    data,
    Options? options,
  }) async {
    var handler = _handleRequest(path, data: data);
    return await _requestClient?.dio.download(handler['path'], savePath,
        data: handler['data'],
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress);
  }

  static Map<String, dynamic> _handleRequest(String path,
      {Map<String, dynamic>? data, bool isFormData = true}) {
    Map<String, dynamic> newData =
        ApiRequestUtils.handleDynamicPathWithData(path, data ?? {});
    if (isFormData) {
      newData['data'] = FormData.fromMap(
          newData['data'], ApiRequestOptions.instance!.listFormat);
    }
    return newData;
  }

  static Future<Either<ActionRequestError, T?>?> _handleResponse<T>(
      {Response? response}) async {
    Either<ActionRequestError, T?>? either;
    try {
      either = right(responseBuilder != null
          ? responseBuilder!(response?.data)
          : response?.data);
    } catch (e) {
      either = left(ActionRequestError(e, res: response));
    }
    return either;
  }

  static Future<Either<ActionRequestError, T?>?> _handleError<T>(
          {Object? error}) async =>
      left(ActionRequestError(error));
}

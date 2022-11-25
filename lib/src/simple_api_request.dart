import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../api_request.dart';
import 'api_request_exception.dart';
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

  Future<Either<ApiRequestException, T?>?> get<T>(String path,
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

  Future<Either<ApiRequestException, T?>?> post<T>(String path,
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

  Future<Either<ApiRequestException, T?>?> put<T>(String path,
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

  Future<Either<ApiRequestException, T?>?> delete<T>(String path,
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

  static Future<Either<ApiRequestException, T?>?> _handleResponse<T>(
      {Response? response}) async {
    Either<ApiRequestException, T?>? toReturn;
    if (response != null) {
      int statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode < 300) {
        toReturn = right(responseBuilder != null
            ? responseBuilder!(response.data)
            : response.data);
      }
    } else {
      toReturn = left(
          ApiRequestException(message: "error", type: ApiExceptionType.custom));
    }
    return toReturn;
  }

  static Future<Either<ApiRequestException, T?>?> _handleError<T>(
      {Object? error}) async {
    Either<ApiRequestException, T?>? toReturn;
    if (error != null && error is DioError) {
      int statusCode = error.response?.statusCode ?? 0;
      if (statusCode >= 400 && statusCode < 500) {
        toReturn = left(ApiRequestException(
            message: error.response?.data?["message"]?.toString() ??
                error.response?.statusMessage ??
                "client_error",
            type: ApiExceptionType.client,
            errors: error.response?.data?["errors"],
            statusCode: error.response?.statusCode,
            statusMessage: error.response?.statusMessage));
      }
      if (statusCode >= 500) {
        toReturn = left(ApiRequestException(
            message:
                "${error.response?.statusCode} : ${error.response?.statusMessage}",
            type: ApiExceptionType.server,
            statusCode: statusCode,
            statusMessage: error.response?.statusMessage));
      }
    } else {
      toReturn = left(
          ApiRequestException(message: "error", type: ApiExceptionType.custom));
    }
    return toReturn;
  }
}

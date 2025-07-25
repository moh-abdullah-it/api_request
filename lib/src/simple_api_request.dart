import 'package:fpdart/fpdart.dart';

import '../api_request.dart';
import 'utils/api_request_utils.dart';

class SimpleApiRequest {
  final RequestClient _requestClient;
  final ResponseBuilder? _responseBuilder;
  final bool _withAuth;

  SimpleApiRequest._({
    required RequestClient requestClient,
    ResponseBuilder? responseBuilder,
    bool withAuth = false,
  })  : _requestClient = requestClient,
        _responseBuilder = responseBuilder,
        _withAuth = withAuth {
    _requestClient.configAuth(_withAuth);
  }

  factory SimpleApiRequest.init() {
    final client = RequestClient.instance;
    if (client == null) {
      throw StateError('RequestClient instance is not initialized');
    }
    return SimpleApiRequest._(requestClient: client);
  }

  factory SimpleApiRequest.withAuth() {
    final client = RequestClient.instance;
    if (client == null) {
      throw StateError('RequestClient instance is not initialized');
    }
    return SimpleApiRequest._(requestClient: client, withAuth: true);
  }

  factory SimpleApiRequest.withBuilder(
    ResponseBuilder builder, {
    bool withAuth = false,
  }) {
    final client = RequestClient.instance;
    if (client == null) {
      throw StateError('RequestClient instance is not initialized');
    }
    return SimpleApiRequest._(
      requestClient: client,
      responseBuilder: builder,
      withAuth: withAuth,
    );
  }

  Future<Either<ActionRequestError, T?>?> get<T>(String path,
      {Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onReceiveProgress}) async {
    final handler =
        _handleRequest(path, data: queryParameters, isFormData: false);
    try {
      final response = await _requestClient.dio.get(handler['path'],
          queryParameters: handler['data'],
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress);
      return _handleResponse<T>(response: response);
    } catch (e) {
      return _handleError<T>(error: e);
    }
  }

  Future<Either<ActionRequestError, T?>?> post<T>(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) async {
    final handler = _handleRequest(path, data: data);
    try {
      final response = await _requestClient.dio.post(handler['path'],
          data: handler['data'],
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress);
      return _handleResponse<T>(response: response);
    } catch (e) {
      return _handleError<T>(error: e);
    }
  }

  Future<Either<ActionRequestError, T?>?> put<T>(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) async {
    final handler = _handleRequest(path, data: data);
    try {
      final response = await _requestClient.dio.put(handler['path'],
          data: handler['data'],
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
          onSendProgress: onSendProgress);
      return _handleResponse<T>(response: response);
    } catch (e) {
      return _handleError<T>(error: e);
    }
  }

  Future<Either<ActionRequestError, T?>?> delete<T>(String path,
      {Map<String, dynamic>? data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken}) async {
    final handler = _handleRequest(path, data: data);
    try {
      final response = await _requestClient.dio.delete(handler['path'],
          data: handler['data'],
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);
      return _handleResponse<T>(response: response);
    } catch (e) {
      return _handleError<T>(error: e);
    }
  }

  Future<Response?> download(
    String path,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    final handler = _handleRequest(path, data: data);
    return await _requestClient.dio.download(handler['path'], savePath,
        data: handler['data'],
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader);
  }

  Map<String, dynamic> _handleRequest(String path,
      {Map<String, dynamic>? data, bool isFormData = true}) {
    final newData =
        ApiRequestUtils.handleDynamicPathWithData(path, data ?? {});
    if (isFormData && newData['data'] is Map<String, dynamic>) {
      newData['data'] = FormData.fromMap(
          newData['data'], ApiRequestOptions.instance!.listFormat);
    }
    return newData;
  }

  Future<Either<ActionRequestError, T?>?> _handleResponse<T>({
    Response? response,
  }) async {
    try {
      final result = _responseBuilder != null
          ? _responseBuilder(response?.data)
          : response?.data;
      return right(result);
    } catch (e) {
      return left(ActionRequestError(e, res: response));
    }
  }

  Future<Either<ActionRequestError, T?>?> _handleError<T>({
    Object? error,
  }) async =>
      left(ActionRequestError(error));
}

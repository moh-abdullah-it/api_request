
import 'package:fpdart/fpdart.dart';

import '../api_request.dart';
import 'utils/api_request_utils.dart';

abstract class ApiResource {
  
  bool get authRequired => false;

  String get path;

  Map<String, dynamic> get toMap => {};

  ResponseBuilder? _responseBuilder;

  RequestClient? _requestClient = RequestClient.instance;

  Future<Either<ActionRequestError, T?>?> get<T>([String? path = null]) async {
    return await _get<T>(path ?? this.path);
  }

  ApiResource withBuilder(ResponseBuilder builder) {
    _responseBuilder = builder;
    return this;
  }

  Future<Either<ActionRequestError, T?>?> _get<T>(
      String path, { Map<String, dynamic>? queryParameters,
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
      return _handleResponse<T>(response: response);
    } catch (e) {
      return _handleError(error: e);
    }
  }

  Map<String, dynamic> _handleRequest(String path,
      {Map<String, dynamic>? data, bool isFormData = true}) {
    _requestClient?.configAuth(authRequired);
    Map<String, dynamic> newData =
    ApiRequestUtils.handleDynamicPathWithData(path, data ?? {});
    if (isFormData) {
      newData['data'] = FormData.fromMap(
          newData['data'], ApiRequestOptions.instance!.listFormat);
    }
    return newData;
  }

   Future<Either<ActionRequestError, T?>?> _handleResponse<T>(
      {Response? response}) async {
    Either<ActionRequestError, T?>? either;
    try {
      either = right(_responseBuilder != null
          ? _responseBuilder!(response?.data)
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
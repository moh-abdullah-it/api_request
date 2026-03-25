import 'dart:convert';

import 'package:dio/dio.dart';

import 'background_request_config.dart';
import 'background_result.dart';

/// Executes API requests inside a background isolate.
///
/// This class creates a fresh [Dio] instance from the snapshotted
/// [BackgroundRequestConfig] and performs the HTTP request. It automatically
/// detects the request type (standard / upload / download) and dispatches
/// to the appropriate handler.
///
/// **Important**: This class is designed to run in a background isolate
/// where main-isolate singletons (like `RequestClient`, `ApiRequestOptions`)
/// are not available. All configuration is read from the config object.
class BackgroundRequestExecutor {
  /// Executes a background request and returns the result.
  ///
  /// Automatically detects the request type from the config:
  /// - [config.isDownload] → file download via `dio.download()`
  /// - [config.isMultipart] → multipart file upload
  /// - Otherwise → standard HTTP request
  static Future<BackgroundResult> execute(
    BackgroundRequestConfig config,
  ) async {
    final dio = _createDio(config);
    try {
      if (config.isDownload) return await _executeDownload(dio, config);
      if (config.isMultipart) return await _executeUpload(dio, config);
      return await _executeStandard(dio, config);
    } on DioException catch (e) {
      return BackgroundResult.failure(
        taskTag: config.taskTag,
        statusCode: e.response?.statusCode,
        errorMessage: e.message ?? e.toString(),
      );
    } catch (e) {
      return BackgroundResult.failure(
        taskTag: config.taskTag,
        errorMessage: e.toString(),
      );
    } finally {
      dio.close();
    }
  }

  /// Creates a new Dio instance configured from the background config.
  static Dio _createDio(BackgroundRequestConfig config) {
    final dio = Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeoutMs != null
          ? Duration(milliseconds: config.connectTimeoutMs!)
          : const Duration(seconds: 30),
      headers: Map<String, dynamic>.from(config.headers),
    ));

    if (config.authToken != null) {
      final prefix = config.tokenType ?? '';
      dio.options.headers['Authorization'] = '$prefix${config.authToken}';
    }

    return dio;
  }

  /// Executes a standard HTTP request (GET/POST/PUT/DELETE).
  static Future<BackgroundResult> _executeStandard(
    Dio dio,
    BackgroundRequestConfig config,
  ) async {
    Response response;

    switch (config.method.toUpperCase()) {
      case 'GET':
        response = await dio.get(
          config.path,
          queryParameters: config.queryParameters,
        );
        break;
      case 'POST':
        response = await dio.post(
          config.path,
          data: config.body,
          queryParameters: config.queryParameters,
        );
        break;
      case 'PUT':
        response = await dio.put(
          config.path,
          data: config.body,
          queryParameters: config.queryParameters,
        );
        break;
      case 'DELETE':
        response = await dio.delete(
          config.path,
          data: config.body,
          queryParameters: config.queryParameters,
        );
        break;
      default:
        return BackgroundResult.failure(
          taskTag: config.taskTag,
          errorMessage: 'Unsupported HTTP method: ${config.method}',
        );
    }

    String? responseBody;
    if (response.data != null) {
      responseBody = response.data is String
          ? response.data as String
          : jsonEncode(response.data);
    }

    return BackgroundResult.success(
      taskTag: config.taskTag,
      statusCode: response.statusCode,
      responseBody: responseBody,
    );
  }

  /// Executes a multipart file upload.
  static Future<BackgroundResult> _executeUpload(
    Dio dio,
    BackgroundRequestConfig config,
  ) async {
    final formDataMap = <String, dynamic>{};

    for (final entry in config.uploadFiles!.entries) {
      formDataMap[entry.key] = await MultipartFile.fromFile(
        entry.value,
        filename: entry.value.split('/').last,
      );
    }

    if (config.formData != null) {
      formDataMap.addAll(config.formData!);
    }

    final response = await dio.post(
      config.path,
      data: FormData.fromMap(formDataMap),
      queryParameters: config.queryParameters,
    );

    String? responseBody;
    if (response.data != null) {
      responseBody = response.data is String
          ? response.data as String
          : jsonEncode(response.data);
    }

    return BackgroundResult.success(
      taskTag: config.taskTag,
      statusCode: response.statusCode,
      responseBody: responseBody,
    );
  }

  /// Executes a file download using `dio.download()`.
  static Future<BackgroundResult> _executeDownload(
    Dio dio,
    BackgroundRequestConfig config,
  ) async {
    final response = await dio.download(
      config.path,
      config.savePath!,
      queryParameters: config.queryParameters,
    );

    return BackgroundResult.downloadSuccess(
      taskTag: config.taskTag,
      savedFilePath: config.savePath!,
      statusCode: response.statusCode,
    );
  }
}

import 'dart:convert';

/// Serializable configuration for a background API request.
///
/// This class captures all the information needed to execute an HTTP request
/// in a background isolate. Since background isolates cannot access singletons
/// from the main isolate, all settings are snapshotted at scheduling time.
///
/// Supports three request types, detected automatically:
/// - **Standard** — Regular HTTP requests (GET/POST/PUT/DELETE)
/// - **Upload** — Multipart file uploads ([uploadFiles] is set)
/// - **Download** — File downloads ([savePath] is set)
///
/// ## Serialization
///
/// The config is serialized to/from a flat `Map<String, Object>` compatible
/// with WorkManager's input data constraints (primitive types + String only).
///
/// ```dart
/// final config = BackgroundRequestConfig(
///   baseUrl: 'https://api.example.com',
///   path: '/data',
///   method: 'POST',
///   taskTag: 'sync-data',
/// );
///
/// final inputData = config.toInputData();
/// final restored = BackgroundRequestConfig.fromInputData(inputData);
/// ```
class BackgroundRequestConfig {
  /// Base URL for the API server.
  final String baseUrl;

  /// Resolved path (no `{id}` placeholders — already substituted).
  final String path;

  /// HTTP method: `'GET'`, `'POST'`, `'PUT'`, or `'DELETE'`.
  final String method;

  /// HTTP headers to include with the request.
  final Map<String, String> headers;

  /// JSON body for standard requests (non-upload).
  final Map<String, dynamic>? body;

  /// Query parameters appended to the URL.
  final Map<String, dynamic>? queryParameters;

  /// Auth token to include in the Authorization header.
  final String? authToken;

  /// Token prefix (e.g. `'Bearer '`).
  final String? tokenType;

  /// Connection timeout in milliseconds.
  final int? connectTimeoutMs;

  /// Unique tag identifying this background task.
  final String taskTag;

  /// File paths for multipart upload: `fieldName → filePath`.
  final Map<String, String>? uploadFiles;

  /// Additional form data fields sent with file uploads.
  final Map<String, dynamic>? formData;

  /// Local path where a downloaded file should be saved.
  final String? savePath;

  BackgroundRequestConfig({
    required this.baseUrl,
    required this.path,
    required this.method,
    this.headers = const {},
    this.body,
    this.queryParameters,
    this.authToken,
    this.tokenType,
    this.connectTimeoutMs,
    required this.taskTag,
    this.uploadFiles,
    this.formData,
    this.savePath,
  });

  /// Whether this config represents a multipart file upload.
  bool get isMultipart => uploadFiles != null && uploadFiles!.isNotEmpty;

  /// Whether this config represents a file download.
  bool get isDownload => savePath != null;

  /// Serializes to a flat map compatible with WorkManager input data.
  ///
  /// Complex values (headers, body, queryParameters, uploadFiles, formData)
  /// are JSON-encoded as strings since WorkManager only supports primitives.
  Map<String, Object> toInputData() {
    final data = <String, Object>{
      'baseUrl': baseUrl,
      'path': path,
      'method': method,
      'taskTag': taskTag,
    };

    if (headers.isNotEmpty) {
      data['headers'] = jsonEncode(headers);
    }
    if (body != null) {
      data['body'] = jsonEncode(body);
    }
    if (queryParameters != null) {
      data['queryParameters'] = jsonEncode(queryParameters);
    }
    if (authToken != null) {
      data['authToken'] = authToken!;
    }
    if (tokenType != null) {
      data['tokenType'] = tokenType!;
    }
    if (connectTimeoutMs != null) {
      data['connectTimeoutMs'] = connectTimeoutMs!;
    }
    if (uploadFiles != null) {
      data['uploadFiles'] = jsonEncode(uploadFiles);
    }
    if (formData != null) {
      data['formData'] = jsonEncode(formData);
    }
    if (savePath != null) {
      data['savePath'] = savePath!;
    }

    return data;
  }

  /// Deserializes from WorkManager input data.
  factory BackgroundRequestConfig.fromInputData(Map<String, dynamic> data) {
    return BackgroundRequestConfig(
      baseUrl: data['baseUrl'] as String,
      path: data['path'] as String,
      method: data['method'] as String,
      taskTag: data['taskTag'] as String,
      headers: data['headers'] != null
          ? Map<String, String>.from(
              jsonDecode(data['headers'] as String) as Map,
            )
          : const {},
      body: data['body'] != null
          ? jsonDecode(data['body'] as String) as Map<String, dynamic>
          : null,
      queryParameters: data['queryParameters'] != null
          ? jsonDecode(data['queryParameters'] as String)
              as Map<String, dynamic>
          : null,
      authToken: data['authToken'] as String?,
      tokenType: data['tokenType'] as String?,
      connectTimeoutMs: data['connectTimeoutMs'] as int?,
      uploadFiles: data['uploadFiles'] != null
          ? Map<String, String>.from(
              jsonDecode(data['uploadFiles'] as String) as Map,
            )
          : null,
      formData: data['formData'] != null
          ? jsonDecode(data['formData'] as String) as Map<String, dynamic>
          : null,
      savePath: data['savePath'] as String?,
    );
  }

  @override
  String toString() {
    return 'BackgroundRequestConfig(taskTag: $taskTag, method: $method, '
        'path: $path, isMultipart: $isMultipart, isDownload: $isDownload)';
  }
}

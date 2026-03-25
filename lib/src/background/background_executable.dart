import 'package:api_request/api_request.dart';
import 'package:workmanager/workmanager.dart';

import '../utils/api_request_utils.dart';

/// A unified mixin that adds background execution capability to any action.
///
/// Apply this mixin to [RequestAction], [FileUploadAction], or
/// [FileDownloadAction] subclasses. It automatically detects the action type
/// and builds the appropriate [BackgroundRequestConfig].
///
/// ## Standard request
///
/// ```dart
/// class SyncDataAction extends ApiRequestAction<Map<String, dynamic>>
///     with BackgroundExecutable<Map<String, dynamic>, ApiRequest> {
///   @override
///   String get path => '/data/sync';
///   @override
///   RequestMethod get method => RequestMethod.POST;
///   @override
///   ResponseBuilder<Map<String, dynamic>> get responseBuilder =>
///       (data) => data as Map<String, dynamic>;
/// }
///
/// // One-off background execution
/// await SyncDataAction()
///   .where('userId', 123)
///   .scheduleInBackground(taskTag: 'sync-now');
///
/// // Periodic background execution
/// await SyncDataAction().schedulePeriodicInBackground(
///   taskTag: 'sync-periodic',
///   frequency: Duration(minutes: 15),
/// );
/// ```
///
/// ## File upload
///
/// ```dart
/// class UploadAvatarAction extends FileUploadAction<User>
///     with BackgroundExecutable<User, FileUploadRequest> {
///   UploadAvatarAction(File file) : super({'avatar': file});
///   @override String get path => '/users/avatar';
///   @override ResponseBuilder<User> get responseBuilder =>
///       (data) => User.fromJson(data);
/// }
///
/// await UploadAvatarAction(avatarFile)
///   .scheduleInBackground(taskTag: 'upload-avatar');
/// ```
///
/// ## File download
///
/// ```dart
/// class DownloadReportAction extends FileDownloadAction
///     with BackgroundExecutable<Response, ApiRequest> {
///   DownloadReportAction(String savePath) : super(savePath);
///   @override String get path => '/reports/{reportId}/download';
/// }
///
/// await DownloadReportAction('/storage/report.pdf')
///   .where('reportId', 'abc123')
///   .scheduleInBackground(taskTag: 'download-report');
/// ```
mixin BackgroundExecutable<T, R extends ApiRequest> on RequestAction<T, R> {
  /// Schedules a one-off background execution of this action.
  ///
  /// [taskTag] uniquely identifies the task (used for cancellation and results).
  /// [initialDelay] delays execution from now.
  /// [constraints] platform-specific constraints (e.g. network type).
  Future<void> scheduleInBackground({
    required String taskTag,
    Duration initialDelay = Duration.zero,
    Constraints? constraints,
  }) async {
    final config = await _buildBackgroundConfig(taskTag);
    await BackgroundRequestManager.instance!.scheduleOneOff(
      config: config,
      initialDelay: initialDelay,
      constraints: constraints,
    );
  }

  /// Schedules a periodic background execution of this action.
  ///
  /// [taskTag] uniquely identifies the task.
  /// [frequency] interval between executions (minimum 15 min on iOS).
  /// [initialDelay] delay before first execution.
  /// [constraints] platform-specific constraints.
  Future<void> schedulePeriodicInBackground({
    required String taskTag,
    Duration frequency = const Duration(minutes: 15),
    Duration initialDelay = Duration.zero,
    Constraints? constraints,
  }) async {
    final config = await _buildBackgroundConfig(taskTag);
    await BackgroundRequestManager.instance!.schedulePeriodic(
      config: config,
      frequency: frequency,
      initialDelay: initialDelay,
      constraints: constraints,
    );
  }

  /// Builds a [BackgroundRequestConfig] by snapshotting current action state.
  ///
  /// Detects the action type automatically:
  /// - [FileUploadAction] → captures file paths and form data
  /// - [FileDownloadAction] → captures save path
  /// - Otherwise → standard request with body/query
  Future<BackgroundRequestConfig> _buildBackgroundConfig(
    String taskTag,
  ) async {
    final options = ApiRequestOptions.instance!;
    final baseUrl = await options.getBaseUrlString();
    String? token = authRequired ? await options.getTokenString() : null;

    // Resolve dynamic path variables
    final allData = combinedData;
    final resolved = ApiRequestUtils.handleDynamicPathWithData(path, allData);
    final resolvedPath = resolved['path'] as String;
    final remainingData = resolved['data'] as Map<String, dynamic>;

    // Detect action type
    Map<String, String>? uploadFiles;
    Map<String, dynamic>? formDataFields;
    String? savePath;

    if (this is FileUploadAction) {
      final uploadAction = this as FileUploadAction;
      uploadFiles = uploadAction.files
          .map((key, file) => MapEntry(key, file.path));
      formDataFields = Map<String, dynamic>.from(uploadAction.uploadFormData);
    }

    if (this is FileDownloadAction) {
      final downloadAction = this as FileDownloadAction;
      savePath = downloadAction.savePath;
    }

    // Determine body and query parameters based on method and type
    Map<String, dynamic>? body;
    Map<String, dynamic>? queryParams;
    final explicitQuery = combinedQuery;

    if (method == RequestMethod.GET) {
      // For GET, remaining data goes to query params
      final mergedQuery = <String, dynamic>{};
      mergedQuery.addAll(remainingData);
      mergedQuery.addAll(explicitQuery);
      queryParams = mergedQuery.isNotEmpty ? mergedQuery : null;
    } else if (uploadFiles == null) {
      // For non-GET, non-upload: remaining data goes to body
      body = remainingData.isNotEmpty ? remainingData : null;
      queryParams = explicitQuery.isNotEmpty ? explicitQuery : null;
    } else {
      // Upload: file data handled separately, query params if any
      queryParams = explicitQuery.isNotEmpty ? explicitQuery : null;
    }

    // Snapshot headers
    final headers = <String, String>{};
    options.defaultHeaders.forEach((k, v) => headers[k] = v.toString());

    return BackgroundRequestConfig(
      baseUrl: baseUrl,
      path: resolvedPath,
      method: method.name,
      headers: headers,
      body: body,
      queryParameters: queryParams,
      authToken: token,
      tokenType: options.tokenType,
      connectTimeoutMs: options.connectTimeout?.inMilliseconds,
      taskTag: taskTag,
      uploadFiles: uploadFiles,
      formData: formDataFields,
      savePath: savePath,
    );
  }
}

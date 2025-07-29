import 'dart:async';

import 'package:api_request/api_request.dart';
import 'package:fpdart/fpdart.dart';

import '../utils/api_request_utils.dart';

/// A specialized action for downloading files from remote URLs.
///
/// This action extends [ApiRequestAction] to provide a streamlined interface
/// for file download operations. It supports progress tracking, cancellation,
/// and automatic path variable resolution.
///
/// ## Features
///
/// - **Progress Tracking**: Monitor download progress with callbacks
/// - **Cancellation Support**: Cancel downloads using [CancelToken]
/// - **Dynamic Paths**: Support for path variables like `/files/{id}`
/// - **Error Handling**: Built-in error handling with Either pattern
/// - **Stream Support**: Progress updates via Dart Streams
/// - **Large File Support**: Efficient streaming for large files
///
/// ## Basic Usage
///
/// ```dart
/// class DownloadFileAction extends FileDownloadAction {
///   DownloadFileAction(String savePath) : super(savePath);
///
///   @override
///   String get path => '/files/{fileId}';
/// }
///
/// // Execute download
/// final result = await DownloadFileAction('/local/downloads/file.pdf')
///   .where('fileId', 'abc123')
///   .execute();
/// ```
///
/// ## Progress Tracking
///
/// ```dart
/// final action = DownloadFileAction('/downloads/video.mp4')
///   .where('videoId', 123)
///   .onProgress((received, total) {
///     final percentage = (received / total * 100).round();
///     print('Downloaded: $percentage%');
///   });
///
/// final result = await action.execute();
/// ```
///
/// ## Cancellation
///
/// ```dart
/// final cancelToken = CancelToken();
/// final action = DownloadFileAction('/downloads/large-file.zip')
///   .withCancelToken(cancelToken);
///
/// // Start download
/// action.execute();
///
/// // Cancel after 10 seconds
/// Timer(Duration(seconds: 10), () => cancelToken.cancel());
/// ```
///
/// ## Stream-based Progress
///
/// ```dart
/// final action = DownloadFileAction('/downloads/file.pdf');
///
/// action.progressStream.listen((progress) {
///   print('Progress: ${progress.percentage}%');
/// });
///
/// final result = await action.execute();
/// ```
///
/// See also:
/// - [ApiRequestAction] for the base action implementation
/// - [SimpleApiRequest.download] for direct download functionality
/// - [RequestClient] for the underlying HTTP client
abstract class FileDownloadAction extends ApiRequestAction<Response> {
  /// The local file path where the downloaded file will be saved
  final String savePath;

  /// Optional progress callback for monitoring download progress
  ProgressCallback? _onReceiveProgress;

  /// Unified progress handler using the new progress system
  DownloadProgressHandler? _downloadProgressHandler;

  /// Optional cancellation token for aborting downloads
  CancelToken? _cancelToken;

  /// Whether to delete the partial file if download fails
  bool _deleteOnError = true;

  /// Custom header name for content length (defaults to standard header)
  String _lengthHeader = Headers.contentLengthHeader;

  /// Stream controller for emitting download progress updates
  final StreamController<DownloadProgress> _progressController =
      StreamController<DownloadProgress>.broadcast();

  /// Creates a new file download action.
  ///
  /// Parameters:
  /// - [savePath]: The local file path where the file will be saved
  ///
  /// Example:
  /// ```dart
  /// class DownloadDocumentAction extends FileDownloadAction {
  ///   DownloadDocumentAction() : super('/documents/download.pdf');
  ///
  ///   @override
  ///   String get path => '/documents/{docId}';
  /// }
  /// ```
  FileDownloadAction(this.savePath) : super();

  /// Stream of download progress updates.
  ///
  /// Emits [DownloadProgress] objects containing current progress information
  /// including bytes received, total bytes, and completion percentage.
  ///
  /// Example:
  /// ```dart
  /// action.progressStream.listen((progress) {
  ///   print('${progress.percentage}% - ${progress.received}/${progress.total}');
  /// });
  /// ```
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  /// The HTTP method for file downloads is always GET.
  @override
  RequestMethod get method => RequestMethod.GET;

  /// File downloads don't need response building since they write to disk.
  ///
  /// This method returns the raw [Response] object containing metadata
  /// about the download operation.
  @override
  ResponseBuilder<Response> get responseBuilder => (data) => data as Response;

  /// Sets a progress callback to monitor download progress.
  ///
  /// The callback receives the number of bytes received and the total
  /// number of bytes expected (if known from Content-Length header).
  ///
  /// Parameters:
  /// - [onProgress]: Callback function for progress updates
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final action = DownloadFileAction('/downloads/file.pdf')
  ///   .onProgress((received, total) {
  ///     if (total > 0) {
  ///       final percentage = (received / total * 100).round();
  ///       print('Download progress: $percentage%');
  ///     }
  ///   });
  /// ```
  FileDownloadAction onProgress(ProgressCallback onProgress) {
    _onReceiveProgress = (received, total) {
      // Create unified progress data
      final progressData = ProgressData.fromBytes(
        sentBytes: received,
        totalBytes: total,
        type: ProgressType.download,
      );

      // Emit to legacy stream for backward compatibility
      _progressController.add(DownloadProgress(
        received: received,
        total: total,
        percentage: progressData.percentage,
      ));

      // Call new unified progress handler
      _downloadProgressHandler?.call(progressData);

      // Call legacy user callback
      onProgress(received, total);
    };
    return this;
  }

  /// Sets a download progress handler using the unified progress system.
  ///
  /// This method integrates with the new progress tracking infrastructure,
  /// providing consistent progress data across all request types.
  ///
  /// Parameters:
  /// - [handler]: The download progress handler function to call
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final action = DownloadFileAction('/downloads/file.pdf')
  ///   .withDownloadProgress((progress) {
  ///     print('Download: ${progress.percentage}% complete');
  ///     updateProgressBar(progress.percentage);
  ///   });
  /// ```
  FileDownloadAction withDownloadProgress(DownloadProgressHandler handler) {
    _downloadProgressHandler = handler;
    return this;
  }

  /// Sets a cancellation token for aborting the download.
  ///
  /// Parameters:
  /// - [cancelToken]: Token for canceling the download operation
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final cancelToken = CancelToken();
  /// final action = DownloadFileAction('/downloads/file.pdf')
  ///   .withCancelToken(cancelToken);
  ///
  /// // Cancel the download
  /// cancelToken.cancel('User cancelled');
  /// ```
  FileDownloadAction withCancelToken(CancelToken cancelToken) {
    _cancelToken = cancelToken;
    return this;
  }

  /// Configures whether to delete partial files on download failure.
  ///
  /// Parameters:
  /// - [deleteOnError]: Whether to delete partial file on error (default: true)
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final action = DownloadFileAction('/downloads/file.pdf')
  ///   .keepPartialOnError(false); // Keep partial file on error
  /// ```
  FileDownloadAction keepPartialOnError(bool deleteOnError) {
    _deleteOnError = deleteOnError;
    return this;
  }

  /// Sets a custom header name for determining content length.
  ///
  /// Parameters:
  /// - [header]: Header name for content length information
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final action = DownloadFileAction('/downloads/file.pdf')
  ///   .withLengthHeader('X-Content-Length');
  /// ```
  FileDownloadAction withLengthHeader(String header) {
    _lengthHeader = header;
    return this;
  }

  /// Executes the file download operation.
  ///
  /// This method overrides the base implementation to use Dio's download
  /// method instead of a regular HTTP request. It handles progress tracking,
  /// cancellation, and error management.
  ///
  /// Returns:
  /// - `null` if authentication is required but no token is available
  /// - `Left(error)` if the download fails
  /// - `Right(response)` if the download succeeds
  ///
  /// Example:
  /// ```dart
  /// final result = await DownloadFileAction('/downloads/file.pdf')
  ///   .where('fileId', 123)
  ///   .execute();
  ///
  /// result?.fold(
  ///   (error) => print('Download failed: ${error.message}'),
  ///   (response) => print('Download completed: ${response.statusCode}'),
  /// );
  /// ```
  @override
  Future<Either<ActionRequestError, Response>?> execute() async {
    if (authRequired &&
        (await ApiRequestOptions.instance?.getTokenString()) == null) {
      return null;
    }

    try {
      _handleRequest(null);
      onStart();

      final response = await _performDownload();

      if (response != null) {
        onSuccess(response);
        onDone();
        return right(response);
      } else {
        final error =
            ActionRequestError('Download failed: No response received');
        _handleError(error);
        return left(error);
      }
    } catch (e) {
      final error = ActionRequestError(e);
      _handleError(error);
      return left(error);
    } finally {
      await _progressController.close();
    }
  }

  /// Performs the actual download operation using Dio.
  ///
  /// This method handles the low-level download logic including
  /// path resolution, query parameters, and progress tracking.
  Future<Response?> _performDownload() async {
    final requestClient = RequestClient.instance;
    if (requestClient == null) {
      throw StateError('RequestClient instance is not initialized');
    }

    // Build query parameters from data
    final queryParams = Map<String, dynamic>.from(_data);

    // Create unified progress callback if new handler is set but no legacy callback
    ProgressCallback? progressCallback = _onReceiveProgress;
    if (progressCallback == null && _downloadProgressHandler != null) {
      progressCallback = (received, total) {
        final progressData = ProgressData.fromBytes(
          sentBytes: received,
          totalBytes: total,
          type: ProgressType.download,
        );

        // Emit to legacy stream for backward compatibility
        _progressController.add(DownloadProgress(
          received: received,
          total: total,
          percentage: progressData.percentage,
        ));

        // Call new unified progress handler
        _downloadProgressHandler?.call(progressData);
      };
    }

    return await requestClient.dio.download(
      _dynamicPath,
      savePath,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      cancelToken: _cancelToken,
      onReceiveProgress: progressCallback,
      deleteOnError: _deleteOnError,
      lengthHeader: _lengthHeader,
      options: Options(headers: _headers),
    );
  }

  /// Internal method to handle error scenarios.
  void _handleError(ActionRequestError error) {
    onError(error);
    if (ApiRequestOptions.instance!.onError != null && !disableGlobalOnError) {
      ApiRequestOptions.instance!.onError!(error);
    }
    onDone();
  }

  /// Handles request processing and path resolution.
  ///
  /// This method processes the request data and resolves any dynamic
  /// path variables using the existing utility functions.
  void _handleRequest(ApiRequest? request) {
    Map<String, dynamic> mapData = Map.of(toMap.isNotEmpty ? toMap : {});
    mapData.addAll(_data);

    final newData = ApiRequestUtils.handleDynamicPathWithData(path, mapData);
    _dynamicPath = newData['path'];

    // For downloads, we'll use remaining data as query parameters
    _data = Map<String, dynamic>.from(newData['data']);
  }

  /// Additional data parameters for the download request
  Map<String, dynamic> _data = {};

  /// Custom headers for the download request
  final Map<String, dynamic> _headers = {};

  /// The resolved path after dynamic variable substitution
  late String _dynamicPath;
}

/// Represents download progress information.
///
/// This class encapsulates progress data for file download operations,
/// including bytes received, total bytes, and completion percentage.
class DownloadProgress {
  /// Number of bytes received so far
  final int received;

  /// Total number of bytes expected (may be -1 if unknown)
  final int total;

  /// Completion percentage (0-100)
  final double percentage;

  /// Creates a new download progress instance.
  ///
  /// Parameters:
  /// - [received]: Bytes received so far
  /// - [total]: Total bytes expected
  /// - [percentage]: Completion percentage
  const DownloadProgress({
    required this.received,
    required this.total,
    required this.percentage,
  });

  /// Whether the total size is known.
  bool get hasTotalSize => total > 0;

  /// Formatted string representation of progress.
  ///
  /// Example: "1.2 MB / 5.0 MB (24%)"
  String get formattedProgress {
    final receivedMB = (received / 1024 / 1024).toStringAsFixed(1);
    if (hasTotalSize) {
      final totalMB = (total / 1024 / 1024).toStringAsFixed(1);
      return '$receivedMB MB / $totalMB MB (${percentage.round()}%)';
    } else {
      return '$receivedMB MB downloaded';
    }
  }

  @override
  String toString() => formattedProgress;
}

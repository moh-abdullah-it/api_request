import 'progress_data.dart';

/// Function type for handling request progress updates.
///
/// This callback is invoked during HTTP request execution to provide
/// real-time progress information for upload and download operations.
///
/// ## Parameters
///
/// - [progress]: A [ProgressData] object containing current progress information
///   including bytes transferred, total bytes, percentage, and operation type.
///
/// ## Usage
///
/// ```dart
/// ProgressHandler onProgress = (ProgressData progress) {
///   print('${progress.type.name}: ${progress.percentage.toStringAsFixed(1)}%');
///
///   if (progress.isUpload) {
///     updateUploadProgressBar(progress.percentage);
///   } else if (progress.isDownload) {
///     updateDownloadProgressBar(progress.percentage);
///   }
///
///   if (progress.isCompleted) {
///     print('Transfer completed!');
///   }
/// };
/// ```
///
/// ## Common Use Cases
///
/// ### File Upload Progress
/// ```dart
/// final uploadAction = FileUploadAction(file)
///   .withProgress((progress) {
///     if (progress.isUpload) {
///       setState(() {
///         uploadProgress = progress.percentage;
///       });
///     }
///   });
/// ```
///
/// ### Download Progress with UI Updates
/// ```dart
/// final downloadAction = DownloadFileAction(url)
///   .withProgress((progress) {
///     if (progress.isDownload) {
///       progressController.add(progress);
///
///       if (progress.isCompleted) {
///         showSnackBar('Download completed!');
///       }
///     }
///   });
/// ```
///
/// ### Combined Upload/Download Tracking
/// ```dart
/// final apiAction = CreatePostAction(data)
///   .withProgress((progress) {
///     switch (progress.type) {
///       case ProgressType.upload:
///         print('Uploading: ${progress.percentage}%');
///         break;
///       case ProgressType.download:
///         print('Processing response: ${progress.percentage}%');
///         break;
///     }
///   });
/// ```
///
/// ## Integration with Request Actions
///
/// Progress handlers are typically set using fluent API methods:
///
/// - [RequestAction.withProgress] - General progress tracking
/// - [RequestAction.withUploadProgress] - Upload-specific tracking
/// - [RequestAction.withDownloadProgress] - Download-specific tracking
///
/// ## Performance Considerations
///
/// - Progress handlers are called frequently during transfers
/// - Keep handler logic lightweight to avoid blocking the request
/// - Consider throttling UI updates if necessary
/// - Use async operations carefully to avoid blocking progress updates
///
/// ## Error Handling
///
/// Progress handlers should not throw exceptions as this can interrupt
/// the request flow. Use try-catch blocks if performing operations that
/// might fail:
///
/// ```dart
/// ProgressHandler safeHandler = (progress) {
///   try {
///     updateProgressBar(progress.percentage);
///   } catch (e) {
///     print('Progress update failed: $e');
///   }
/// };
/// ```
///
/// See also:
/// - [ProgressData] for the progress information structure
/// - [ProgressType] for operation type definitions
/// - [RequestAction.withProgress] for setting progress handlers
typedef ProgressHandler = void Function(ProgressData progress);

/// Function type for handling upload-specific progress updates.
///
/// This is a specialized version of [ProgressHandler] that only receives
/// upload progress updates ([ProgressType.upload]).
///
/// ## Usage
///
/// ```dart
/// UploadProgressHandler onUpload = (ProgressData progress) {
///   assert(progress.isUpload, 'Should only receive upload progress');
///   updateUploadUI(progress.percentage);
/// };
/// ```
///
/// This typedef provides type safety and clarity when you only need to
/// handle upload progress, making the intent more explicit in your code.
///
/// See also:
/// - [ProgressHandler] for general progress handling
/// - [DownloadProgressHandler] for download-specific handling
typedef UploadProgressHandler = void Function(ProgressData progress);

/// Function type for handling download-specific progress updates.
///
/// This is a specialized version of [ProgressHandler] that only receives
/// download progress updates ([ProgressType.download]).
///
/// ## Usage
///
/// ```dart
/// DownloadProgressHandler onDownload = (ProgressData progress) {
///   assert(progress.isDownload, 'Should only receive download progress');
///   updateDownloadUI(progress.percentage);
/// };
/// ```
///
/// This typedef provides type safety and clarity when you only need to
/// handle download progress, making the intent more explicit in your code.
///
/// See also:
/// - [ProgressHandler] for general progress handling
/// - [UploadProgressHandler] for upload-specific handling
typedef DownloadProgressHandler = void Function(ProgressData progress);

/// Represents the progress of an HTTP request operation.
///
/// This class encapsulates progress information for both upload and download
/// operations, providing detailed metrics about bytes transferred and
/// completion percentage.
///
/// ## Usage
///
/// ```dart
/// ProgressData progress = ProgressData(
///   sentBytes: 1024,
///   totalBytes: 4096,
///   percentage: 25.0,
///   type: ProgressType.upload,
/// );
///
/// print('Progress: ${progress.percentage}% (${progress.sentBytes}/${progress.totalBytes} bytes)');
/// ```
///
/// ## Features
///
/// - **Byte Tracking**: Monitor exact bytes sent/received versus total
/// - **Percentage Calculation**: Automatic percentage calculation with precision
/// - **Operation Type**: Distinguish between upload and download progress
/// - **Completion Detection**: Easy detection of completed operations
///
/// See also:
/// - [ProgressHandler] for handling progress updates
/// - [ProgressType] for operation type definitions
class ProgressData {
  /// The number of bytes that have been sent or received
  final int sentBytes;

  /// The total number of bytes to be transferred
  final int totalBytes;

  /// The completion percentage (0.0 to 100.0)
  final double percentage;

  /// The type of progress operation (upload or download)
  final ProgressType type;

  /// Creates a new progress data instance.
  ///
  /// Parameters:
  /// - [sentBytes]: Number of bytes already transferred
  /// - [totalBytes]: Total bytes to be transferred
  /// - [percentage]: Completion percentage (0.0-100.0)
  /// - [type]: Whether this is upload or download progress
  ///
  /// Example:
  /// ```dart
  /// final progress = ProgressData(
  ///   sentBytes: 2048,
  ///   totalBytes: 8192,
  ///   percentage: 25.0,
  ///   type: ProgressType.upload,
  /// );
  /// ```
  const ProgressData({
    required this.sentBytes,
    required this.totalBytes,
    required this.percentage,
    required this.type,
  });

  /// Creates a ProgressData instance from byte counts.
  ///
  /// Automatically calculates the percentage based on sent and total bytes.
  /// If total bytes is 0, percentage will be 0.0 to avoid division by zero.
  ///
  /// Parameters:
  /// - [sentBytes]: Number of bytes already transferred
  /// - [totalBytes]: Total bytes to be transferred
  /// - [type]: Whether this is upload or download progress
  ///
  /// Returns a new [ProgressData] instance with calculated percentage.
  ///
  /// Example:
  /// ```dart
  /// final progress = ProgressData.fromBytes(
  ///   sentBytes: 1500,
  ///   totalBytes: 3000,
  ///   type: ProgressType.download,
  /// );
  /// // progress.percentage will be 50.0
  /// ```
  factory ProgressData.fromBytes({
    required int sentBytes,
    required int totalBytes,
    required ProgressType type,
  }) {
    final percentage = totalBytes > 0 ? (sentBytes / totalBytes) * 100.0 : 0.0;
    return ProgressData(
      sentBytes: sentBytes,
      totalBytes: totalBytes,
      percentage: percentage,
      type: type,
    );
  }

  /// Whether the operation has completed (100% progress).
  ///
  /// Returns `true` if the percentage is 100.0 or if all bytes have been
  /// transferred (sentBytes >= totalBytes).
  ///
  /// Example:
  /// ```dart
  /// if (progress.isCompleted) {
  ///   print('Transfer completed!');
  /// }
  /// ```
  bool get isCompleted => percentage >= 100.0 || sentBytes >= totalBytes;

  /// Whether this is an upload progress update.
  ///
  /// Returns `true` if the progress type is [ProgressType.upload].
  ///
  /// Example:
  /// ```dart
  /// if (progress.isUpload) {
  ///   updateUploadUI(progress);
  /// }
  /// ```
  bool get isUpload => type == ProgressType.upload;

  /// Whether this is a download progress update.
  ///
  /// Returns `true` if the progress type is [ProgressType.download].
  ///
  /// Example:
  /// ```dart
  /// if (progress.isDownload) {
  ///   updateDownloadUI(progress);
  /// }
  /// ```
  bool get isDownload => type == ProgressType.download;

  /// The remaining bytes to be transferred.
  ///
  /// Calculates the difference between total and sent bytes.
  /// Returns 0 if the operation is completed.
  ///
  /// Example:
  /// ```dart
  /// print('${progress.remainingBytes} bytes remaining');
  /// ```
  int get remainingBytes => totalBytes - sentBytes;

  /// Returns a string representation of the progress data.
  ///
  /// Includes progress type, percentage, and byte information.
  ///
  /// Example output: "ProgressData(upload: 75.0%, 3072/4096 bytes)"
  @override
  String toString() {
    return 'ProgressData(${type.name}: ${percentage.toStringAsFixed(1)}%, $sentBytes/$totalBytes bytes)';
  }

  /// Compares two ProgressData instances for equality.
  ///
  /// Two instances are equal if all their properties match.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressData &&
        other.sentBytes == sentBytes &&
        other.totalBytes == totalBytes &&
        other.percentage == percentage &&
        other.type == type;
  }

  /// Returns the hash code for this ProgressData instance.
  @override
  int get hashCode {
    return Object.hash(sentBytes, totalBytes, percentage, type);
  }
}

/// Defines the type of progress operation being tracked.
///
/// This enum distinguishes between different types of progress operations
/// to allow for appropriate handling and UI updates.
///
/// ## Values
///
/// - [upload]: Progress for sending data to the server
/// - [download]: Progress for receiving data from the server
///
/// ## Usage
///
/// ```dart
/// void handleProgress(ProgressData progress) {
///   switch (progress.type) {
///     case ProgressType.upload:
///       updateUploadProgressBar(progress.percentage);
///       break;
///     case ProgressType.download:
///       updateDownloadProgressBar(progress.percentage);
///       break;
///   }
/// }
/// ```
enum ProgressType {
  /// Progress for uploading data to the server.
  ///
  /// This type is used when tracking the progress of sending request data,
  /// such as form submissions, file uploads, or API requests with large payloads.
  upload,

  /// Progress for downloading data from the server.
  ///
  /// This type is used when tracking the progress of receiving response data,
  /// such as file downloads, large API responses, or streaming content.
  download,
}
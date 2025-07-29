import 'dart:async';
import 'dart:io';

import 'package:api_request/api_request.dart';
import 'package:fpdart/fpdart.dart';

import '../utils/api_request_utils.dart';

/// Request data class for file upload operations.
///
/// This class extends [ApiRequest] to provide structured data for
/// file upload actions, combining file data with additional form fields.
class FileUploadRequest with ApiRequest {
  /// Map of field names to files for upload
  final Map<String, File> files;

  /// Additional form data fields
  final Map<String, dynamic> formData;

  /// Creates a new file upload request.
  ///
  /// Parameters:
  /// - [files]: Map of field names to File objects
  /// - [formData]: Additional form data fields (default: empty)
  FileUploadRequest({
    required this.files,
    this.formData = const {},
  });

  @override
  Map<String, dynamic> toMap() => {
    ...formData,
    // Files will be handled separately in buildRequestData
  };
}

/// A specialized action for uploading files to remote servers.
///
/// This action extends [RequestAction] to provide a streamlined interface
/// for file upload operations with progress tracking, multi-file support,
/// and automatic multipart form data handling.
///
/// ## Features
///
/// - **Progress Tracking**: Monitor upload progress with unified progress system
/// - **Multi-file Support**: Upload multiple files in a single request
/// - **Form Data Integration**: Automatic multipart/form-data encoding
/// - **File Validation**: Built-in file existence and size validation
/// - **Cancellation Support**: Cancel uploads using [CancelToken]
/// - **Error Handling**: Comprehensive error handling with Either pattern
///
/// ## Basic Usage
///
/// ```dart
/// class UploadAvatarAction extends FileUploadAction<User> {
///   UploadAvatarAction(File file) : super({'avatar': file});
///
///   @override
///   String get path => '/users/avatar';
///
///   @override
///   ResponseBuilder<User> get responseBuilder => (data) => User.fromJson(data);
/// }
///
/// // Execute upload
/// final result = await UploadAvatarAction(avatarFile)
///   .withUploadProgress((progress) {
///     print('Upload: ${progress.percentage}%');
///   })
///   .execute();
/// ```
///
/// ## Multi-file Upload
///
/// ```dart
/// class UploadDocumentsAction extends FileUploadAction<List<Document>> {
///   UploadDocumentsAction(List<File> files)
///       : super(Map.fromEntries(
///           files.asMap().entries.map((entry) => 
///             MapEntry('document_${entry.key}', entry.value)
///           )
///         ));
///
///   @override
///   String get path => '/documents/upload';
///
///   @override
///   ResponseBuilder<List<Document>> get responseBuilder => 
///       (data) => (data as List).map((doc) => Document.fromJson(doc)).toList();
/// }
/// ```
///
/// ## Progress Tracking
///
/// ```dart
/// final uploadAction = UploadFileAction(file)
///   .withUploadProgress((progress) {
///     updateProgressBar(progress.percentage);
///     print('Uploaded: ${progress.sentBytes}/${progress.totalBytes} bytes');
///   })
///   .withFormData({'description': 'Profile photo', 'category': 'avatar'});
///
/// final result = await uploadAction.execute();
/// ```
///
/// See also:
/// - [FileDownloadAction] for downloading files
/// - [RequestAction] for the base action implementation
/// - [SimpleApiRequest] for direct upload functionality
abstract class FileUploadAction<T> extends RequestAction<T, FileUploadRequest> {
  /// Map of field names to files for upload
  final Map<String, File> _files;

  /// Additional form data fields
  final Map<String, dynamic> _formData = {};

  /// Upload progress handler using the unified progress system
  UploadProgressHandler? _uploadProgressHandler;

  /// Download progress handler for response processing
  DownloadProgressHandler? _downloadProgressHandler;

  /// Optional cancellation token for aborting uploads
  CancelToken? _cancelToken;

  /// Creates a new file upload action.
  ///
  /// Parameters:
  /// - [files]: Map of field names to File objects for upload
  ///
  /// Example:
  /// ```dart
  /// class UploadPhotoAction extends FileUploadAction<Photo> {
  ///   UploadPhotoAction(File photo) : super({'photo': photo});
  ///
  ///   @override
  ///   String get path => '/photos/upload';
  ///
  ///   @override
  ///   ResponseBuilder<Photo> get responseBuilder => 
  ///       (data) => Photo.fromJson(data);
  /// }
  /// ```
  FileUploadAction(this._files) : super(FileUploadRequest(files: {}, formData: {})) {
    _validateFiles();
  }

  /// Creates a file upload action for a single file.
  ///
  /// This is a convenience constructor for single file uploads.
  ///
  /// Parameters:
  /// - [fieldName]: The form field name for the file
  /// - [file]: The file to upload
  ///
  /// Example:
  /// ```dart
  /// class UploadDocumentAction extends FileUploadAction<Document> {
  ///   UploadDocumentAction.single(File file) 
  ///       : super.single('document', file);
  ///
  ///   @override
  ///   String get path => '/documents';
  /// }
  /// ```
  FileUploadAction.single(String fieldName, File file) 
      : _files = {fieldName: file}, super(FileUploadRequest(files: {}, formData: {})) {
    _validateFiles();
  }

  /// The HTTP method for file uploads is always POST.
  @override
  RequestMethod get method => RequestMethod.POST;

  /// File uploads always require authentication by default.
  ///
  /// Override this property if your upload endpoint doesn't require auth.
  @override
  bool get authRequired => true;

  /// Sets an upload progress handler using the unified progress system.
  ///
  /// This handler will receive progress updates during the file upload phase.
  ///
  /// Parameters:
  /// - [handler]: The upload progress handler function to call
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final action = UploadFileAction(file)
  ///   .withUploadProgress((progress) {
  ///     print('Upload: ${progress.percentage}% complete');
  ///     updateUploadProgressBar(progress.percentage);
  ///   });
  /// ```
  @override
  FileUploadAction<T> withUploadProgress(UploadProgressHandler handler) {
    _uploadProgressHandler = handler;
    return this;
  }

  /// Sets a download progress handler for response processing.
  ///
  /// This handler will receive progress updates while downloading the response
  /// after the upload completes.
  ///
  /// Parameters:
  /// - [handler]: The download progress handler function to call
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final action = UploadFileAction(file)
  ///   .withDownloadProgress((progress) {
  ///     print('Processing response: ${progress.percentage}%');
  ///   });
  /// ```
  @override
  FileUploadAction<T> withDownloadProgress(DownloadProgressHandler handler) {
    _downloadProgressHandler = handler;
    return this;
  }

  /// Sets a general progress handler for both upload and download phases.
  ///
  /// This is a convenience method that sets the same handler for both
  /// upload and download progress updates.
  ///
  /// Parameters:
  /// - [handler]: The progress handler function to call
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final action = UploadFileAction(file)
  ///   .withProgress((progress) {
  ///     print('${progress.type.name}: ${progress.percentage}%');
  ///   });
  /// ```
  @override
  FileUploadAction<T> withProgress(ProgressHandler handler) {
    _uploadProgressHandler = handler;
    _downloadProgressHandler = handler;
    return this;
  }

  /// Adds additional form data fields to the upload request.
  ///
  /// These fields will be included in the multipart form data along
  /// with the files.
  ///
  /// Parameters:
  /// - [data]: Map of field names to values
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final action = UploadFileAction(file)
  ///   .withFormData({
  ///     'title': 'My Document',
  ///     'category': 'personal',
  ///     'isPublic': false,
  ///   });
  /// ```
  FileUploadAction<T> withFormData(Map<String, dynamic> data) {
    _formData.addAll(data);
    return this;
  }

  /// Sets a cancellation token for aborting the upload.
  ///
  /// Parameters:
  /// - [cancelToken]: Token for canceling the upload operation
  ///
  /// Returns the action instance for method chaining.
  ///
  /// Example:
  /// ```dart
  /// final cancelToken = CancelToken();
  /// final action = UploadFileAction(file)
  ///   .withCancelToken(cancelToken);
  ///
  /// // Cancel the upload
  /// cancelToken.cancel('User cancelled');
  /// ```
  FileUploadAction<T> withCancelToken(CancelToken cancelToken) {
    _cancelToken = cancelToken;
    return this;
  }

  /// Builds the request data for the upload.
  ///
  /// This method creates a multipart form data object containing
  /// all files and additional form fields.
  Map<String, dynamic> buildRequestData(FileUploadRequest? request) {
    final formDataMap = <String, dynamic>{};
    
    // Add files to form data
    for (final entry in _files.entries) {
      formDataMap[entry.key] = MultipartFile.fromFileSync(
        entry.value.path,
        filename: entry.value.path.split('/').last,
      );
    }
    
    // Add additional form data
    formDataMap.addAll(_formData);
    
    // Add any data from the request
    if (request != null) {
      formDataMap.addAll(request.toMap());
    }
    
    return formDataMap;
  }

  /// Executes the file upload operation.
  ///
  /// This method overrides the base implementation to handle file uploads
  /// with progress tracking, multipart form data creation, and error management.
  @override
  Future<Either<ActionRequestError, T>?> execute() async {
    if (authRequired &&
        (await ApiRequestOptions.instance?.getTokenString()) == null) {
      return null;
    }

    try {
      _handleRequest(null);
      onStart();

      final response = await _performUpload();

      if (response != null && response.data != null) {
        final result = responseBuilder(response.data);
        onSuccess(result);
        onDone();
        return right(result);
      } else {
        final error = ActionRequestError('Upload failed: No response received');
        _handleError(error);
        return left(error);
      }
    } catch (e) {
      final error = ActionRequestError(e);
      _handleError(error);
      return left(error);
    }
  }

  /// Performs the actual upload operation using Dio.
  ///
  /// This method handles the low-level upload logic including
  /// form data creation, progress tracking, and HTTP request execution.
  Future<Response?> _performUpload() async {
    final requestClient = RequestClient.instance;
    if (requestClient == null) {
      throw StateError('RequestClient instance is not initialized');
    }

    // Build form data from files and additional fields
    final formDataMap = <String, dynamic>{};
    
    // Add files to form data
    for (final entry in _files.entries) {
      formDataMap[entry.key] = MultipartFile.fromFileSync(
        entry.value.path,
        filename: entry.value.path.split('/').last,
      );
    }
    
    // Add additional form data
    formDataMap.addAll(_formData);
    
    // Add any data from the request (if any additional data was set)
    // This is handled through _formData, so no additional processing needed

    final formData = FormData.fromMap(formDataMap);

    // Create progress callbacks
    ProgressCallback? onSendProgress;
    ProgressCallback? onReceiveProgress;

    if (_uploadProgressHandler != null) {
      onSendProgress = (sent, total) {
        final progress = ProgressData.fromBytes(
          sentBytes: sent,
          totalBytes: total,
          type: ProgressType.upload,
        );
        _uploadProgressHandler?.call(progress);
      };
    }

    if (_downloadProgressHandler != null) {
      onReceiveProgress = (received, total) {
        final progress = ProgressData.fromBytes(
          sentBytes: received,
          totalBytes: total,
          type: ProgressType.download,
        );
        _downloadProgressHandler?.call(progress);
      };
    }

    return await requestClient.dio.post(
      _dynamicPath,
      data: formData,
      options: Options(
        headers: _headers,
        contentType: 'multipart/form-data',
      ),
      cancelToken: _cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
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
  void _handleRequest(FileUploadRequest? request) {
    Map<String, dynamic> mapData = Map.of(_formData);

    final newData = ApiRequestUtils.handleDynamicPathWithData(path, mapData);
    _dynamicPath = newData['path'];
  }

  /// Validates that all files exist and are readable.
  void _validateFiles() {
    for (final entry in _files.entries) {
      final file = entry.value;
      final fieldName = entry.key;
      
      if (!file.existsSync()) {
        throw ArgumentError('File for field "$fieldName" does not exist: ${file.path}');
      }
      
      try {
        file.lengthSync(); // Check if file is readable
      } catch (e) {
        throw ArgumentError('File for field "$fieldName" is not readable: ${file.path}');
      }
    }
  }

  /// Gets the total size of all files to be uploaded.
  ///
  /// Returns the combined size in bytes of all files in the upload.
  int get totalFileSize {
    return _files.values.fold(0, (sum, file) => sum + file.lengthSync());
  }

  /// Gets the number of files in the upload.
  int get fileCount => _files.length;

  /// Gets the file names being uploaded.
  List<String> get fileNames {
    return _files.values.map((file) => file.path.split('/').last).toList();
  }

  /// Custom headers for the upload request
  final Map<String, dynamic> _headers = {};

  /// The resolved path after dynamic variable substitution
  late String _dynamicPath;
}
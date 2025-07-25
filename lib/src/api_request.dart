/// Defines how request data should be serialized for transmission.
///
/// This enum determines the format used when sending request data to the server:
/// - [formData]: Multipart form data, useful for file uploads
/// - [bodyData]: JSON data in the request body (default)
enum ContentDataType {
  /// Multipart form data serialization.
  ///
  /// Use this for requests that need to upload files or when the server
  /// expects multipart/form-data content type. This is commonly used
  /// for file uploads and complex form submissions.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// ContentDataType? get contentDataType => ContentDataType.formData;
  /// ```
  formData,

  /// JSON body data serialization (default).
  ///
  /// Use this for standard API requests where data is sent as JSON
  /// in the request body. This is the most common format for REST APIs.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// ContentDataType? get contentDataType => ContentDataType.bodyData;
  /// ```
  bodyData
}

/// A mixin that defines the contract for request data objects.
///
/// Classes that represent request data should implement this mixin to provide
/// serialization capabilities and content type specification. This mixin is
/// used by [RequestAction] to handle request data consistently.
///
/// ## Implementation Requirements
///
/// - [toMap]: Convert the request object to a map for HTTP transmission
/// - [contentDataType]: Specify how the data should be serialized (optional)
///
/// ## Usage Example
///
/// ```dart
/// class CreatePostRequest with ApiRequest {
///   final String title;
///   final String content;
///   final File? image;
///
///   CreatePostRequest({
///     required this.title,
///     required this.content,
///     this.image,
///   });
///
///   @override
///   Map<String, dynamic> toMap() => {
///     'title': title,
///     'content': content,
///     if (image != null) 'image': MultipartFile.fromFileSync(image!.path),
///   };
///
///   @override
///   ContentDataType? get contentDataType =>
///     image != null ? ContentDataType.formData : ContentDataType.bodyData;
/// }
/// ```
///
/// ## Content Type Selection
///
/// The [contentDataType] property determines how the request data is serialized:
/// - `ContentDataType.bodyData` (default): Data is sent as JSON
/// - `ContentDataType.formData`: Data is sent as multipart form data
///
/// ## Integration with Actions
///
/// Request objects are typically used with [RequestAction] subclasses:
///
/// ```dart
/// class CreatePostAction extends RequestAction<Post, CreatePostRequest> {
///   CreatePostAction(CreatePostRequest request) : super(request);
///
///   @override
///   String get path => '/posts';
///
///   @override
///   RequestMethod get method => RequestMethod.POST;
///
///   @override
///   ResponseBuilder<Post> get responseBuilder => (data) => Post.fromJson(data);
/// }
/// ```
///
/// See also:
/// - [RequestAction] for the action base class that uses this mixin
/// - [ContentDataType] for serialization format options
mixin ApiRequest {
  /// Specifies how the request data should be serialized.
  ///
  /// Returns [ContentDataType.bodyData] by default, which serializes
  /// the request as JSON. Override this to return [ContentDataType.formData]
  /// for multipart form data serialization (useful for file uploads).
  ///
  /// Example:
  /// ```dart
  /// @override
  /// ContentDataType? get contentDataType =>
  ///   hasFiles ? ContentDataType.formData : ContentDataType.bodyData;
  /// ```
  ContentDataType? get contentDataType => ContentDataType.bodyData;

  /// Converts the request object to a map for HTTP transmission.
  ///
  /// This method should return a [Map<String, dynamic>] containing all
  /// the data that should be included in the HTTP request. The returned
  /// map will be serialized according to the [contentDataType].
  ///
  /// For [ContentDataType.bodyData], the map is serialized to JSON.
  /// For [ContentDataType.formData], the map is converted to form data.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, dynamic> toMap() => {
  ///   'title': title,
  ///   'content': content,
  ///   'published': isPublished,
  ///   if (tags.isNotEmpty) 'tags': tags,
  /// };
  /// ```
  ///
  /// Returns a map containing the request data.
  Map<String, dynamic> toMap();
}

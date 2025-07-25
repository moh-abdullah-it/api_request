import 'package:api_request/api_request.dart';

/// A simplified base class for API requests that don't require request data.
///
/// This class extends `RequestAction` with a null request parameter, making it
/// ideal for simple API calls that only need path parameters, query parameters,
/// or headers. It's commonly used for GET requests or other operations that
/// don't require a request body.
///
/// ## Usage
///
/// ```dart
/// class GetPostsAction extends ApiRequestAction<List<Post>> {
///   @override
///   String get path => '/posts';
///
///   @override
///   RequestMethod get method => RequestMethod.GET;
///
///   @override
///   ResponseBuilder<List<Post>> get responseBuilder =>
///     (data) => (data as List).map((item) => Post.fromJson(item)).toList();
/// }
///
/// // Execute the request
/// final result = await GetPostsAction().execute();
/// ```
///
/// ## Features
///
/// - **No Request Data**: Perfect for requests that don't need a request body
/// - **Path Parameters**: Support for dynamic path variables like `/posts/{id}`
/// - **Query Parameters**: Add query parameters using `whereQuery()` methods
/// - **Headers**: Add custom headers using `withHeaders()` methods
/// - **Error Handling**: Built-in error handling with Either pattern
/// - **Authentication**: Automatic token management when `authRequired` is true
///
/// ## Example with Dynamic Path and Query Parameters
///
/// ```dart
/// class GetUserPostsAction extends ApiRequestAction<List<Post>> {
///   @override
///   String get path => '/users/{userId}/posts';
///
///   @override
///   RequestMethod get method => RequestMethod.GET;
///
///   @override
///   ResponseBuilder<List<Post>> get responseBuilder =>
///     (data) => (data as List).map((item) => Post.fromJson(item)).toList();
/// }
///
/// // Usage with path and query parameters
/// final result = await GetUserPostsAction()
///   .where('userId', 123)  // Sets {userId} in path
///   .whereQuery('limit', 10)  // Adds ?limit=10 to URL
///   .whereQuery('offset', 0)  // Adds &offset=0 to URL
///   .execute();
/// ```
///
/// See also:
/// - [RequestAction] for the base implementation
/// - [ApiRequest] for the null request parameter type
abstract class ApiRequestAction<T> extends RequestAction<T, ApiRequest> {
  /// Creates a new [ApiRequestAction] with no request data.
  ///
  /// This constructor passes `null` to the parent [RequestAction], indicating
  /// that this action doesn't require a request body or structured request data.
  ApiRequestAction() : super(null);
}

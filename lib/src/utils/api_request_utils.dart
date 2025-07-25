/// Utility functions for API request processing.
///
/// This class provides static helper methods used internally by the
/// API request system for common operations like path variable resolution.
class ApiRequestUtils {
  /// Resolves dynamic path variables and separates them from request data.
  ///
  /// This method processes a path string containing variables in curly braces
  /// (like `/users/{id}/posts`) and replaces them with values from the provided
  /// data map. Any data not used for path variables is returned as remaining
  /// request data.
  ///
  /// ## Variable Resolution
  ///
  /// Path variables are identified by curly braces: `{variableName}`
  /// - If a matching key exists in the data map, the variable is replaced
  /// - The value is converted to string for path substitution
  /// - The key-value pair is removed from the returned data
  ///
  /// ## Data Separation
  ///
  /// Data that doesn't match path variables is preserved and returned
  /// as request data for use in query parameters or request body.
  ///
  /// Parameters:
  /// - [path]: The path string potentially containing variables
  /// - [map]: The data map containing values for substitution
  ///
  /// Returns a map with two keys:
  /// - `'path'`: The resolved path with variables substituted
  /// - `'data'`: Remaining data not used for path variables
  ///
  /// Example:
  /// ```dart
  /// final result = ApiRequestUtils.handleDynamicPathWithData(
  ///   '/users/{id}/posts',
  ///   {'id': 123, 'limit': 10, 'offset': 0}
  /// );
  ///
  /// print(result['path']);  // '/users/123/posts'
  /// print(result['data']);  // {'limit': 10, 'offset': 0}
  /// ```
  ///
  /// ## Use Cases
  ///
  /// This method is used internally by:
  /// - [RequestAction] for resolving dynamic paths
  /// - [ApiResource] for path variable substitution
  /// - [SimpleApiRequest] for URL processing
  ///
  /// ## Path Variable Format
  ///
  /// Variables must be enclosed in curly braces and match map keys exactly:
  /// - Valid: `/users/{userId}` with data `{'userId': 123}`
  /// - Invalid: `/users/{user_id}` with data `{'userId': 123}` (won't match)
  ///
  /// Multiple variables in the same path are supported:
  /// ```dart
  /// final result = ApiRequestUtils.handleDynamicPathWithData(
  ///   '/users/{userId}/posts/{postId}/comments',
  ///   {'userId': 123, 'postId': 456, 'content': 'Hello'}
  /// );
  /// // result['path'] = '/users/123/posts/456/comments'
  /// // result['data'] = {'content': 'Hello'}
  /// ```
  static Map<String, dynamic> handleDynamicPathWithData(
      String path, Map<String, dynamic> map) {
    Map<String, dynamic> newData = {};
    map.keys.forEach((key) {
      if (path.contains('{$key}')) {
        path = path.replaceFirst('{$key}', map[key].toString());
      } else {
        newData[key] = map[key];
      }
    });
    return {'path': path, 'data': newData};
  }
}

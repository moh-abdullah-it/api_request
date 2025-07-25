/// A Flutter package that provides an action-based HTTP request library using Dio.
///
/// This library follows the Single Responsibility Principle by creating small,
/// dedicated classes for each API request. It provides a comprehensive solution
/// for HTTP communication with features like:
///
/// - Action-based request handling with `ApiRequestAction` and `RequestAction`
/// - Global configuration management through `ApiRequestOptions`
/// - Automatic token management and authentication
/// - Request/response interceptors
/// - Performance monitoring and reporting
/// - Dynamic path resolution with variable substitution
/// - Functional error handling using the Either pattern
/// - Multi-environment support with runtime base URL switching
///
/// ## Quick Start
///
/// ```dart
/// import 'package:api_request/api_request.dart';
///
/// // Configure global options
/// ApiRequestOptions.instance!.config(
///   baseUrl: 'https://api.example.com',
///   token: 'your-auth-token',
/// );
///
/// // Create a simple request action
/// class GetPostAction extends ApiRequestAction<Post> {
///   @override
///   String get path => '/posts/{id}';
///
///   @override
///   RequestMethod get method => RequestMethod.GET;
///
///   @override
///   ResponseBuilder<Post> get responseBuilder => (data) => Post.fromJson(data);
/// }
///
/// // Execute the request
/// final result = await GetPostAction().where('id', 123).execute();
/// ```
library api_request;

/// Re-export Dio for convenient access to HTTP client features
export 'package:dio/dio.dart';

/// Action classes for creating API request handlers
export 'src/actions/api_request_action.dart';
export 'src/actions/request_action.dart';

/// Core API request functionality
export 'src/api_request.dart';
export 'src/api_request_client.dart';
export 'src/api_request_error.dart';
export 'src/api_request_options.dart';

/// HTTP interceptors for request/response processing
export 'src/interceptors/api_interceptor.dart';

/// Performance monitoring and reporting tools
export 'src/performance/api_request_performance.dart';
export 'src/performance/performance_report.dart';

/// Utility classes for simplified API requests
export 'src/simple_api_request.dart';
export 'src/api_resource.dart';

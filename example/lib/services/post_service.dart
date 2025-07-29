import 'package:api_request/api_request.dart';
import 'package:fpdart/fpdart.dart';
import '../models/post.dart';

/// Service class to handle all post-related API operations
class PostService {
  static const String _basePath = 'posts';

  /// Fetch all posts
  static Future<Either<ActionRequestError, List<Post>>?> getAllPosts() async {
    final action = GetPostsAction();
    return await action.execute();
  }

  /// Fetch a single post by ID
  static Future<Either<ActionRequestError, Post>?> getPost(int id) async {
    final action = GetPostAction()..where('id', id);
    return await action.execute();
  }

  /// Create a new post
  static Future<Either<ActionRequestError, Post>?> createPost({
    required int userId,
    required String title,
    required String body,
  }) async {
    final request = CreatePostRequest(
      userId: userId,
      title: title,
      body: body,
    );
    final action = CreatePostAction(request);
    return await action.execute();
  }

  /// Create a new post with progress tracking
  static Future<Either<ActionRequestError, Post>?> createPostWithProgress({
    required int userId,
    required String title,
    required String body,
    ProgressHandler? onProgress,
    UploadProgressHandler? onUploadProgress,
  }) async {
    final request = CreatePostRequest(
      userId: userId,
      title: title,
      body: body,
    );

    final action = CreatePostAction(request);

    // Add progress tracking if provided
    if (onProgress != null) {
      action.withProgress(onProgress);
    }

    if (onUploadProgress != null) {
      action.withUploadProgress(onUploadProgress);
    }

    return await action.execute();
  }

  /// Create a new post using streaming with progress tracking
  static Stream<Post?> createPostStream({
    required int userId,
    required String title,
    required String body,
    ProgressHandler? onProgress,
  }) {
    final request = CreatePostRequest(
      userId: userId,
      title: title,
      body: body,
    );

    final action = CreatePostAction(request);

    // Add progress tracking if provided
    if (onProgress != null) {
      action.withProgress(onProgress);
    }

    // Start the request and return the stream
    action.onQueue();
    return action.stream;
  }

  /// Update an existing post
  static Future<Either<ActionRequestError, Post>?> updatePost({
    required int id,
    required int userId,
    required String title,
    required String body,
  }) async {
    final request = UpdatePostRequest(
      id: id,
      userId: userId,
      title: title,
      body: body,
    );
    final action = UpdatePostAction(request);
    return await action.execute();
  }

  /// Delete a post
  static Future<Either<ActionRequestError, bool>?> deletePost(int id) async {
    final action = DeletePostAction()..where('id', id);
    return await action.execute();
  }
}

/// Action to get all posts
class GetPostsAction extends ApiRequestAction<List<Post>> {
  @override
  bool get authRequired => false;

  @override
  String get path => PostService._basePath;

  @override
  RequestMethod get method => RequestMethod.GET;

  @override
  ResponseBuilder<List<Post>> get responseBuilder => (data) {
        if (data is List) {
          return data
              .map((json) => Post.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        throw FormatException(
            'Expected a list of posts, got: ${data.runtimeType}');
      };
}

/// Action to get a single post
class GetPostAction extends ApiRequestAction<Post> {
  @override
  bool get authRequired => false;

  @override
  String get path => '${PostService._basePath}/{id}';

  @override
  RequestMethod get method => RequestMethod.GET;

  @override
  ResponseBuilder<Post> get responseBuilder => (data) {
        if (data is Map<String, dynamic>) {
          return Post.fromJson(data);
        }
        throw FormatException(
            'Expected a post object, got: ${data.runtimeType}');
      };
}

/// Request data for creating a post
class CreatePostRequest with ApiRequest {
  final int userId;
  final String title;
  final String body;

  CreatePostRequest({
    required this.userId,
    required this.title,
    required this.body,
  });

  @override
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
      };
}

/// Action to create a post
class CreatePostAction extends RequestAction<Post, CreatePostRequest> {
  CreatePostAction(CreatePostRequest request) : super(request);

  @override
  bool get authRequired => false;

  @override
  String get path => PostService._basePath;

  @override
  RequestMethod get method => RequestMethod.POST;

  @override
  ResponseBuilder<Post> get responseBuilder => (data) {
        if (data is Map<String, dynamic>) {
          return Post.fromJson(data);
        }
        throw FormatException(
            'Expected a post object, got: ${data.runtimeType}');
      };
}

/// Request data for updating a post
class UpdatePostRequest with ApiRequest {
  final int id;
  final int userId;
  final String title;
  final String body;

  UpdatePostRequest({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
      };
}

/// Action to update a post
class UpdatePostAction extends RequestAction<Post, UpdatePostRequest> {
  UpdatePostAction(UpdatePostRequest request) : super(request);

  @override
  bool get authRequired => false;

  @override
  String get path => '${PostService._basePath}/{id}';

  @override
  RequestMethod get method => RequestMethod.PUT;

  @override
  ResponseBuilder<Post> get responseBuilder => (data) {
        if (data is Map<String, dynamic>) {
          return Post.fromJson(data);
        }
        throw FormatException(
            'Expected a post object, got: ${data.runtimeType}');
      };
}

/// Action to delete a post
class DeletePostAction extends ApiRequestAction<bool> {
  @override
  bool get authRequired => false;

  @override
  String get path => '${PostService._basePath}/{id}';

  @override
  RequestMethod get method => RequestMethod.DELETE;

  @override
  ResponseBuilder<bool> get responseBuilder =>
      (data) => true; // Delete typically returns empty response
}

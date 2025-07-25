import 'package:api_request/api_request.dart';
import 'package:fpdart/fpdart.dart';
import '../models/post.dart';

/// Mock service for testing and offline demonstration
class MockPostService {
  static const Duration _mockDelay = Duration(milliseconds: 800);
  
  static final List<Post> _mockPosts = [
    const Post(
      id: 1,
      userId: 1,
      title: 'Welcome to API Request Package',
      body: 'This is a demonstration of the API Request package with clean architecture and best practices. This post is generated locally to show the UI and functionality.',
    ),
    const Post(
      id: 2,
      userId: 1,
      title: 'Clean Architecture Example',
      body: 'This example showcases how to structure your Flutter app with proper separation of concerns, service layers, and error handling using the API Request package.',
    ),
    const Post(
      id: 3,
      userId: 2,
      title: 'Error Handling Best Practices',
      body: 'The API Request package provides excellent error handling capabilities with Either types from fpdart, allowing for functional programming patterns in Flutter.',
    ),
    const Post(
      id: 4,
      userId: 2,
      title: 'Performance Monitoring',
      body: 'Built-in performance monitoring helps you track API request performance and optimize your application\'s network operations.',
    ),
    const Post(
      id: 5,
      userId: 3,
      title: 'Modern Flutter UI',
      body: 'This example uses Material 3 design principles with clean, modern UI components and proper state management.',
    ),
  ];

  /// Simulate fetching all posts
  static Future<Either<ActionRequestError, List<Post>>?> getAllPosts() async {
    await Future.delayed(_mockDelay);
    
    // Always succeed for consistent testing
    return right(List.from(_mockPosts));
  }

  /// Simulate fetching a single post by ID
  static Future<Either<ActionRequestError, Post>?> getPost(int id) async {
    await Future.delayed(_mockDelay);
    
    final post = _mockPosts.where((p) => p.id == id).firstOrNull;
    if (post == null) {
      return left(ActionRequestError('Post with ID $id not found'));
    }
    
    return right(post);
  }

  /// Simulate creating a new post
  static Future<Either<ActionRequestError, Post>?> createPost({
    required int userId,
    required String title,
    required String body,
  }) async {
    await Future.delayed(_mockDelay);
    
    final newPost = Post(
      id: _mockPosts.length + 1,
      userId: userId,
      title: title,
      body: body,
    );
    
    _mockPosts.add(newPost);
    return right(newPost);
  }

  /// Simulate updating a post
  static Future<Either<ActionRequestError, Post>?> updatePost({
    required int id,
    required int userId,
    required String title,
    required String body,
  }) async {
    await Future.delayed(_mockDelay);
    
    final index = _mockPosts.indexWhere((p) => p.id == id);
    if (index == -1) {
      return left(ActionRequestError('Post with ID $id not found'));
    }
    
    final updatedPost = Post(
      id: id,
      userId: userId,
      title: title,
      body: body,
    );
    
    _mockPosts[index] = updatedPost;
    return right(updatedPost);
  }

  /// Simulate deleting a post
  static Future<Either<ActionRequestError, bool>?> deletePost(int id) async {
    await Future.delayed(_mockDelay);
    
    final index = _mockPosts.indexWhere((p) => p.id == id);
    if (index == -1) {
      return left(ActionRequestError('Post with ID $id not found'));
    }
    
    _mockPosts.removeAt(index);
    return right(true);
  }
}
import 'package:api_request/api_request.dart';
import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'models/api_error.dart';
import 'models/post.dart';
import 'services/post_service.dart';
import 'services/mock_post_service.dart';
import 'widgets/post_card.dart';
import 'widgets/network_status_banner.dart';
import 'screens/post_detail_screen.dart';
import 'screens/downloads_screen.dart';

/// Example token provider functions
String getStaticToken() {
  return 'your-static-token-here';
}

Future<String> getAsyncToken() async {
  // Simulate async token retrieval (e.g., from secure storage)
  await Future.delayed(const Duration(milliseconds: 100));
  return 'your-async-token-here';
}

void main() {
  // Configure API requests globally (only if not using mock data)
  if (!AppConfig.useMockData) {
    ApiRequestOptions.instance?.config(
      // Enable request/response logging in debug mode
      enableLog: AppConfig.enableNetworkLogs,

      // Base URL for all API requests
      baseUrl: AppConfig.baseUrl,

      // Custom error builder for parsing API errors
      errorBuilder: (json) => ApiError.fromJson(json),

      // Token configuration
      tokenType: ApiRequestOptions.bearer,

      // Global error handler
      onError: (error) {
        print('🚨 Global API Error: ${error.message}');
        // You could also send errors to crash reporting service here
      },

      // Token providers (uncomment as needed)
      // token: 'static-token-here',
      // getToken: getStaticToken,
      getAsyncToken: getAsyncToken,

      // Default headers for all requests
      defaultHeaders: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },

      // Default query parameters (e.g., for localization)
      // defaultQueryParameters: {'locale': 'en'},

      // Connection timeout
      connectTimeout: AppConfig.networkTimeout,
    );
  }

  runApp(const PostsApp());
}

class PostsApp extends StatelessWidget {
  const PostsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posts Demo - API Request Package',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PostsListScreen(),
    const DownloadsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Downloads',
          ),
        ],
      ),
    );
  }
}

class PostsListScreen extends StatefulWidget {
  const PostsListScreen({Key? key}) : super(key: key);

  @override
  State<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends State<PostsListScreen> {
  List<Post> posts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = AppConfig.useMockData
          ? await MockPostService.getAllPosts()
          : await PostService.getAllPosts();

      result?.fold(
        (error) {
          if (mounted) {
            setState(() {
              errorMessage = AppConfig.useMockData
                  ? 'Mock API Error: ${error.message}'
                  : 'Failed to load posts: ${error.message}';
              isLoading = false;
            });
          }
        },
        (loadedPosts) {
          if (mounted) {
            setState(() {
              posts = loadedPosts;
              isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Unexpected error: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToPost(Post post) async {
    final wasDeleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(postId: post.id),
      ),
    );

    // Refresh the list if the post was deleted
    if (wasDeleted == true) {
      _loadPosts();
    }
  }

  Future<void> _deletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "${post.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = AppConfig.useMockData
            ? await MockPostService.deletePost(post.id)
            : await PostService.deletePost(post.id);

        result?.fold(
          (error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete post: ${error.message}'),
                backgroundColor: Colors.red,
              ),
            );
          },
          (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadPosts(); // Refresh the list
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPerformanceReport() {
    final report = ApiRequestPerformance.instance?.actionsReport;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Report'),
        content: SingleChildScrollView(
          child: Text(report?.toString() ?? 'No performance data available'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _testProgressTracking() async {
    if (AppConfig.useMockData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progress tracking works best with live API data'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final result = await PostService.createPostWithProgress(
        userId: 1,
        title: 'Test Progress Post',
        body: 'Testing progress tracking functionality',
        onProgress: (progress) {
          print(
              'Progress: ${progress.type.name} - ${progress.percentage.toStringAsFixed(1)}%');

          // Show progress in UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Progress: ${progress.type.name} - ${progress.percentage.toStringAsFixed(1)}%',
              ),
              duration: const Duration(milliseconds: 500),
            ),
          );
        },
        onUploadProgress: (progress) {
          print('Upload: ${progress.sentBytes}/${progress.totalBytes} bytes');
        },
      );

      result?.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Progress test failed: ${error.message}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (post) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Progress test completed! Created post: ${post.title}'),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progress test error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            AppConfig.useMockData ? 'Posts Demo (Mock)' : 'Posts Demo (Live)'),
        actions: [
          if (!AppConfig.useMockData)
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: _showPerformanceReport,
              tooltip: 'Performance Report',
            ),
          IconButton(
            icon: const Icon(Icons.trending_up),
            onPressed: _testProgressTracking,
            tooltip: 'Test Progress Tracking',
          ),
          IconButton(
            icon:
                Icon(AppConfig.useMockData ? Icons.offline_bolt : Icons.cloud),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Data Source'),
                  content: Text(
                    AppConfig.useMockData
                        ? 'Currently using mock data for demonstration. To use live API, set AppConfig.useMockData to false.'
                        : 'Currently using live API data from ${AppConfig.baseUrl}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            tooltip:
                AppConfig.useMockData ? 'Using Mock Data' : 'Using Live API',
          ),
        ],
      ),
      body: Column(
        children: [
          const NetworkStatusBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPosts,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading posts...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('No posts found'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostCard(
          post: post,
          onTap: () => _navigateToPost(post),
          onDelete: () => _deletePost(post),
        );
      },
    );
  }
}

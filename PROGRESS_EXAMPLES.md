# Progress Tracking Examples

This document provides comprehensive examples of using the progress tracking system across different scenarios and use cases.

## 📱 Flutter UI Integration Examples

### 1. Linear Progress Bar with RequestAction

```dart
class UploadProgressScreen extends StatefulWidget {
  final File file;
  
  const UploadProgressScreen({Key? key, required this.file}) : super(key: key);
  
  @override
  _UploadProgressScreenState createState() => _UploadProgressScreenState();
}

class _UploadProgressScreenState extends State<UploadProgressScreen> {
  double _uploadProgress = 0.0;
  double _downloadProgress = 0.0;
  bool _isUploading = false;
  String _statusMessage = 'Ready to upload';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('File Upload with Progress')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _uploadProgress / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 4),
                    Text('${_uploadProgress.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Response Processing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _downloadProgress / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 4),
                    Text('${_downloadProgress.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(_statusMessage, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isUploading ? null : _startUpload,
              child: Text(_isUploading ? 'Uploading...' : 'Start Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startUpload() async {
    setState(() {
      _isUploading = true;
      _statusMessage = 'Starting upload...';
    });

    final result = await UploadFileAction(widget.file)
      .withUploadProgress((progress) {
        setState(() {
          _uploadProgress = progress.percentage;
          _statusMessage = 'Uploading: ${(progress.sentBytes / 1024).round()} KB / ${(progress.totalBytes / 1024).round()} KB';
        });
      })
      .withDownloadProgress((progress) {
        setState(() {
          _downloadProgress = progress.percentage;
          _statusMessage = 'Processing response...';
        });
      })
      .withFormData({
        'description': 'User uploaded file',
        'category': 'documents',
      })
      .execute();

    setState(() {
      _isUploading = false;
    });

    result?.fold(
      (error) {
        setState(() {
          _statusMessage = 'Upload failed: ${error.message}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed'), backgroundColor: Colors.red),
        );
      },
      (response) {
        setState(() {
          _statusMessage = 'Upload completed successfully!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload completed!'), backgroundColor: Colors.green),
        );
      },
    );
  }
}
```

### 2. Circular Progress with Animation

```dart
class AnimatedProgressWidget extends StatefulWidget {
  @override
  _AnimatedProgressWidgetState createState() => _AnimatedProgressWidgetState();
}

class _AnimatedProgressWidgetState extends State<AnimatedProgressWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _currentProgress = 0.0;
  String _progressText = '0%';
  Color _progressColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _animation.value / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                    ),
                  ),
                  Text(
                    _progressText,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _startProgressDemo,
            child: Text('Start Demo Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _startProgressDemo() async {
    final result = await DemoRequestAction()
      .withProgress((progress) {
        _updateProgress(progress);
      })
      .execute();
  }

  void _updateProgress(ProgressData progress) {
    setState(() {
      _currentProgress = progress.percentage;
      _progressText = '${progress.percentage.toStringAsFixed(1)}%';
      _progressColor = progress.isUpload ? Colors.blue : Colors.green;
    });

    _animation = Tween<double>(
      begin: _animation.value,
      end: progress.percentage,
    ).animate(_animationController);

    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
```

## 🔄 Stream-Based Progress Examples

### 3. Progress Stream with Multiple Subscriptions

```dart
class ProgressStreamManager {
  final StreamController<ProgressData> _progressController = 
      StreamController<ProgressData>.broadcast();
  
  final StreamController<String> _statusController = 
      StreamController<String>.broadcast();

  // Public streams
  Stream<ProgressData> get progressStream => _progressController.stream;
  Stream<String> get statusStream => _statusController.stream;

  Future<void> executeRequestWithStreams() async {
    _statusController.add('Initializing request...');

    final result = await LargeDataRequestAction()
      .withProgress((progress) {
        // Send to progress stream
        _progressController.add(progress);
        
        // Send status updates
        if (progress.isUpload) {
          _statusController.add('Uploading: ${progress.percentage.toStringAsFixed(1)}%');
        } else if (progress.isDownload) {
          _statusController.add('Downloading: ${progress.percentage.toStringAsFixed(1)}%');
        }
        
        if (progress.isCompleted) {
          _statusController.add('${progress.type.name} completed!');
        }
      })
      .execute();

    result?.fold(
      (error) => _statusController.add('Error: ${error.message}'),
      (data) => _statusController.add('Request completed successfully'),
    );
  }

  void dispose() {
    _progressController.close();
    _statusController.close();
  }
}

// Usage in widget
class StreamProgressWidget extends StatefulWidget {
  @override
  _StreamProgressWidgetState createState() => _StreamProgressWidgetState();
}

class _StreamProgressWidgetState extends State<StreamProgressWidget> {
  late ProgressStreamManager _streamManager;

  @override
  void initState() {
    super.initState();
    _streamManager = ProgressStreamManager();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress indicator
        StreamBuilder<ProgressData>(
          stream: _streamManager.progressStream,
          builder: (context, snapshot) {
            final progress = snapshot.data;
            return LinearProgressIndicator(
              value: progress != null ? progress.percentage / 100 : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress?.isUpload == true ? Colors.blue : Colors.green,
              ),
            );
          },
        ),
        
        // Status text
        StreamBuilder<String>(
          stream: _streamManager.statusStream,
          builder: (context, snapshot) {
            return Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                snapshot.data ?? 'Ready',
                style: TextStyle(fontSize: 14),
              ),
            );
          },
        ),
        
        ElevatedButton(
          onPressed: () => _streamManager.executeRequestWithStreams(),
          child: Text('Start Streaming Request'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _streamManager.dispose();
    super.dispose();
  }
}
```

## 📊 Performance Monitoring Examples

### 4. Advanced Performance Dashboard

```dart
class PerformanceDashboard extends StatefulWidget {
  @override
  _PerformanceDashboardState createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard> {
  List<PerformanceReport> _reports = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Performance Dashboard')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runPerformanceTest,
                    child: Text(_isLoading ? 'Running Tests...' : 'Run Performance Test'),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _clearReports,
                  child: Text('Clear'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(report.actionName ?? 'Unknown Action'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Duration: ${report.duration?.inMilliseconds}ms'),
                        if (report.hasProgressData) ...[
                          Text('Uploaded: ${_formatBytes(report.uploadBytes)}'),
                          Text('Downloaded: ${_formatBytes(report.downloadBytes)}'),
                          Text('Transfer Rate: ${_formatTransferRate(report.transferRate)}'),
                        ],
                      ],
                    ),
                    trailing: report.hasProgressData
                        ? Icon(Icons.analytics, color: Colors.green)
                        : Icon(Icons.timer, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runPerformanceTest() async {
    setState(() {
      _isLoading = true;
    });

    // Run multiple requests with different characteristics
    final testActions = [
      () => SmallDataRequestAction().withProgress(_trackProgress).execute(),
      () => LargeDataRequestAction().withProgress(_trackProgress).execute(),
      () => FileUploadAction(await _createTestFile())
          .withProgress(_trackProgress)
          .execute(),
    ];

    for (final action in testActions) {
      await action();
      await Future.delayed(Duration(milliseconds: 500)); // Small delay between requests
    }

    _updateReports();
    
    setState(() {
      _isLoading = false;
    });
  }

  void _trackProgress(ProgressData progress) {
    // Progress tracking is handled automatically by performance monitoring
    print('${progress.type.name}: ${progress.percentage}%');
  }

  void _updateReports() {
    final performance = ApiRequestPerformance.instance;
    if (performance != null) {
      setState(() {
        _reports = performance.actionsReport.values
            .where((report) => report != null)
            .cast<PerformanceReport>()
            .toList()
          ..sort((a, b) => (b.duration?.inMicroseconds ?? 0)
              .compareTo(a.duration?.inMicroseconds ?? 0));
      });
    }
  }

  void _clearReports() {
    setState(() {
      _reports.clear();
    });
    // Note: This doesn't actually clear the global performance data
    // In a real app, you might want to add a clear method to ApiRequestPerformance
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(unitIndex > 0 ? 1 : 0)} ${units[unitIndex]}';
  }

  String _formatTransferRate(double bytesPerSecond) {
    return '${_formatBytes(bytesPerSecond.round())}/s';
  }

  Future<File> _createTestFile() async {
    // Create a temporary test file for upload testing
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/test_file.txt');
    await file.writeAsString('Test file content for upload testing' * 100);
    return file;
  }
}
```

## 🔗 Advanced Integration Examples

### 5. Progress with Dio Interceptors

```dart
class ProgressInterceptor extends Interceptor {
  final ProgressHandler? progressHandler;
  
  ProgressInterceptor(this.progressHandler);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add custom progress tracking logic here if needed
    print('Request started: ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log successful requests with response size
    final responseSize = response.data?.toString().length ?? 0;
    print('Response received: ${responseSize} bytes');
    handler.next(response);
  }
}

// Usage with custom interceptor
class CustomProgressAction extends RequestAction<Data, Request> {
  CustomProgressAction(Request request) : super(request);

  @override
  void onInit() {
    super.onInit();
    
    // Add custom interceptor for this action
    final customInterceptor = ProgressInterceptor(
      (progress) => print('Custom progress: ${progress.percentage}%'),
    );
    
    // Note: This is conceptual - actual interceptor integration would depend on your needs
  }

  // ... rest of implementation
}
```

### 6. Progress with State Management (Provider/Bloc)

```dart
// Provider example
class ProgressProvider extends ChangeNotifier {
  double _uploadProgress = 0.0;
  double _downloadProgress = 0.0;
  bool _isLoading = false;
  String _statusMessage = 'Ready';

  double get uploadProgress => _uploadProgress;
  double get downloadProgress => _downloadProgress;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;

  Future<void> executeRequest(RequestAction action) async {
    _isLoading = true;
    _statusMessage = 'Starting request...';
    notifyListeners();

    final result = await action
      .withUploadProgress((progress) {
        _uploadProgress = progress.percentage;
        _statusMessage = 'Uploading: ${progress.percentage.toStringAsFixed(1)}%';
        notifyListeners();
      })
      .withDownloadProgress((progress) {
        _downloadProgress = progress.percentage;
        _statusMessage = 'Processing: ${progress.percentage.toStringAsFixed(1)}%';
        notifyListeners();
      })
      .execute();

    _isLoading = false;
    result?.fold(
      (error) {
        _statusMessage = 'Error: ${error.message}';
      },
      (data) {
        _statusMessage = 'Completed successfully';
      },
    );
    notifyListeners();
  }

  void reset() {
    _uploadProgress = 0.0;
    _downloadProgress = 0.0;
    _isLoading = false;
    _statusMessage = 'Ready';
    notifyListeners();
  }
}

// Widget using Provider
class ProgressProviderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressProvider>(
      builder: (context, progressProvider, child) {
        return Column(
          children: [
            LinearProgressIndicator(
              value: progressProvider.uploadProgress / 100,
              backgroundColor: Colors.blue[100],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressProvider.downloadProgress / 100,
              backgroundColor: Colors.green[100],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 16),
            Text(progressProvider.statusMessage),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: progressProvider.isLoading
                  ? null
                  : () => progressProvider.executeRequest(SomeAction()),
              child: Text(progressProvider.isLoading ? 'Loading...' : 'Start Request'),
            ),
          ],
        );
      },
    );
  }
}
```

## 🎛️ Custom Progress Implementations

### 7. Throttled Progress Updates

```dart
class ThrottledProgressHandler {
  final ProgressHandler originalHandler;
  final Duration throttleDuration;
  DateTime? _lastUpdate;

  ThrottledProgressHandler(this.originalHandler, this.throttleDuration);

  void call(ProgressData progress) {
    final now = DateTime.now();
    
    if (_lastUpdate == null || 
        now.difference(_lastUpdate!) >= throttleDuration ||
        progress.isCompleted) {
      originalHandler(progress);
      _lastUpdate = now;
    }
  }
}

// Usage
final throttledHandler = ThrottledProgressHandler(
  (progress) => updateExpensiveUI(progress),
  Duration(milliseconds: 100), // Update UI at most 10 times per second
);

final result = await SomeAction()
  .withProgress(throttledHandler.call)
  .execute();
```

### 8. Progress with Persistence

```dart
class PersistentProgressTracker {
  static const String _keyPrefix = 'progress_';
  final SharedPreferences _prefs;
  
  PersistentProgressTracker(this._prefs);

  Future<void> saveProgress(String requestId, ProgressData progress) async {
    final key = '$_keyPrefix$requestId';
    final data = {
      'sentBytes': progress.sentBytes,
      'totalBytes': progress.totalBytes,
      'percentage': progress.percentage,
      'type': progress.type.name,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await _prefs.setString(key, jsonEncode(data));
  }

  ProgressData? loadProgress(String requestId) {
    final key = '$_keyPrefix$requestId';
    final dataString = _prefs.getString(key);
    
    if (dataString != null) {
      try {
        final data = jsonDecode(dataString) as Map<String, dynamic>;
        return ProgressData(
          sentBytes: data['sentBytes'] as int,
          totalBytes: data['totalBytes'] as int,
          percentage: data['percentage'] as double,
          type: data['type'] == 'upload' ? ProgressType.upload : ProgressType.download,
        );
      } catch (e) {
        print('Failed to load progress: $e');
      }
    }
    return null;
  }

  Future<void> clearProgress(String requestId) async {
    final key = '$_keyPrefix$requestId';
    await _prefs.remove(key);
  }
}

// Usage with persistent progress
class PersistentProgressExample {
  final PersistentProgressTracker _tracker;
  
  PersistentProgressExample(this._tracker);

  Future<void> executeWithPersistentProgress(String requestId) async {
    // Load previous progress if available
    final savedProgress = _tracker.loadProgress(requestId);
    if (savedProgress != null) {
      print('Resuming from ${savedProgress.percentage}%');
    }

    final result = await SomeAction()
      .withProgress((progress) async {
        // Save progress
        await _tracker.saveProgress(requestId, progress);
        
        // Update UI
        updateProgressUI(progress);
        
        if (progress.isCompleted) {
          // Clean up saved progress
          await _tracker.clearProgress(requestId);
        }
      })
      .execute();
  }
}
```

## 🧪 Testing Progress Implementations

### 9. Progress Testing Utilities

```dart
class ProgressTestHelper {
  final List<ProgressData> capturedProgress = [];
  late ProgressHandler handler;

  ProgressTestHelper() {
    handler = (progress) {
      capturedProgress.add(progress);
    };
  }

  void verifyProgressSequence() {
    expect(capturedProgress.isNotEmpty, true, reason: 'Should capture progress updates');
    
    // Verify progress is non-decreasing
    for (int i = 1; i < capturedProgress.length; i++) {
      expect(
        capturedProgress[i].percentage >= capturedProgress[i - 1].percentage,
        true,
        reason: 'Progress should not decrease',
      );
    }
    
    // Verify final progress reaches 100%
    if (capturedProgress.isNotEmpty) {
      final finalProgress = capturedProgress.last;
      expect(finalProgress.isCompleted, true, reason: 'Final progress should be completed');
    }
  }

  void verifyProgressTypes(List<ProgressType> expectedTypes) {
    final actualTypes = capturedProgress.map((p) => p.type).toSet().toList();
    expect(actualTypes, containsAll(expectedTypes));
  }

  void clear() {
    capturedProgress.clear();
  }
}

// Test example
void main() {
  group('Progress Tracking Tests', () {
    test('should track upload progress correctly', () async {
      final helper = ProgressTestHelper();
      
      final result = await UploadTestAction()
        .withUploadProgress(helper.handler)
        .execute();
      
      helper.verifyProgressSequence();
      helper.verifyProgressTypes([ProgressType.upload]);
      
      expect(result, isNotNull);
      result?.fold(
        (error) => fail('Expected success but got error: ${error.message}'),
        (data) => expect(data, isNotNull),
      );
    });
  });
}
```

These examples demonstrate comprehensive usage patterns for the progress tracking system across different scenarios, UI frameworks, and architectural approaches. Each example is designed to be practical and ready to adapt to specific application needs.
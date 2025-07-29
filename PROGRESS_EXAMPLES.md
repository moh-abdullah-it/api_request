# Progress Tracking Examples

This document provides comprehensive examples of using the progress tracking system across different scenarios and use cases.

## 📱 Flutter UI Examples

### Basic Progress Bar Integration

```dart
class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('File Upload')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _uploadProgress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text('${_uploadProgress.toStringAsFixed(1)}%'),
            SizedBox(height: 16),
            Text(_statusMessage),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadFile,
              child: Text(_isUploading ? 'Uploading...' : 'Upload File'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile() async {
    final file = await _pickFile(); // Your file picker logic
    if (file == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _statusMessage = 'Starting upload...';
    });

    try {
      final result = await UploadFileAction(file)
        .withUploadProgress((progress) {
          setState(() {
            _uploadProgress = progress.percentage;
            _statusMessage = 'Uploading: ${(progress.sentBytes / 1024).round()} KB / ${(progress.totalBytes / 1024).round()} KB';
          });
        })
        .withFormData({
          'description': 'User uploaded file',
          'category': 'documents',
        })
        .execute();

      result?.fold(
        (error) {
          setState(() {
            _statusMessage = 'Upload failed: ${error.message}';
          });
        },
        (response) {
          setState(() {
            _statusMessage = 'Upload completed successfully!';
          });
        },
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
```

### Circular Progress with Speed Display

```dart
class DownloadProgressWidget extends StatefulWidget {
  final String fileUrl;
  final String fileName;

  DownloadProgressWidget({required this.fileUrl, required this.fileName});

  @override
  _DownloadProgressWidgetState createState() => _DownloadProgressWidgetState();
}

class _DownloadProgressWidgetState extends State<DownloadProgressWidget> {
  double _progress = 0.0;
  String _speed = '0 KB/s';
  String _eta = '';
  int _startTime = 0;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _progress / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                Text(
                  '${_progress.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(widget.fileName, style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Speed: $_speed'),
            if (_eta.isNotEmpty) Text('ETA: $_eta'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startDownload,
              child: Text('Download'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    _startTime = DateTime.now().millisecondsSinceEpoch;
    
    final result = await DownloadFileAction('/downloads/${widget.fileName}')
      .withDownloadProgress((progress) {
        setState(() {
          _progress = progress.percentage;
          
          // Calculate speed
          final elapsed = (DateTime.now().millisecondsSinceEpoch - _startTime) / 1000;
          if (elapsed > 0) {
            final speed = progress.sentBytes / elapsed; // bytes per second
            _speed = '${(speed / 1024).toStringAsFixed(1)} KB/s';
            
            // Calculate ETA
            if (progress.percentage > 0 && progress.percentage < 100) {
              final remaining = progress.totalBytes - progress.sentBytes;
              final etaSeconds = remaining / speed;
              _eta = '${etaSeconds.round()}s';
            }
          }
        });
      })
      .execute();
  }
}
```

### Multi-File Upload with Individual Progress

```dart
class MultiFileUploadWidget extends StatefulWidget {
  @override
  _MultiFileUploadWidgetState createState() => _MultiFileUploadWidgetState();
}

class _MultiFileUploadWidgetState extends State<MultiFileUploadWidget> {
  List<FileUploadItem> _uploadItems = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _selectFiles,
          child: Text('Select Files'),
        ),
        SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _uploadItems.length,
            itemBuilder: (context, index) {
              final item = _uploadItems[index];
              return Card(
                child: ListTile(
                  leading: _getStatusIcon(item.status),
                  title: Text(item.fileName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: item.progress / 100,
                        backgroundColor: Colors.grey[300],
                      ),
                      SizedBox(height: 4),
                      Text('${item.progress.toStringAsFixed(1)}% - ${item.statusText}'),
                    ],
                  ),
                  trailing: item.status == UploadStatus.uploading
                      ? IconButton(
                          icon: Icon(Icons.cancel),
                          onPressed: () => _cancelUpload(index),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        if (_uploadItems.isNotEmpty)
          ElevatedButton(
            onPressed: _startUploads,
            child: Text('Upload All'),
          ),
      ],
    );
  }

  Future<void> _selectFiles() async {
    // Your file selection logic
    final files = await _pickMultipleFiles();
    setState(() {
      _uploadItems = files.map((file) => FileUploadItem(
        file: file,
        fileName: file.path.split('/').last,
        status: UploadStatus.pending,
        progress: 0.0,
        statusText: 'Ready to upload',
      )).toList();
    });
  }

  Future<void> _startUploads() async {
    for (int i = 0; i < _uploadItems.length; i++) {
      if (_uploadItems[i].status == UploadStatus.pending) {
        await _uploadFile(i);
      }
    }
  }

  Future<void> _uploadFile(int index) async {
    final item = _uploadItems[index];
    
    setState(() {
      item.status = UploadStatus.uploading;
      item.statusText = 'Uploading...';
    });

    try {
      final result = await UploadSingleFileAction(item.file)
        .withUploadProgress((progress) {
          setState(() {
            item.progress = progress.percentage;
            item.statusText = '${(progress.sentBytes / 1024).round()} KB uploaded';
          });
        })
        .execute();

      result?.fold(
        (error) {
          setState(() {
            item.status = UploadStatus.failed;
            item.statusText = 'Failed: ${error.message}';
          });
        },
        (response) {
          setState(() {
            item.status = UploadStatus.completed;
            item.statusText = 'Upload completed';
            item.progress = 100.0;
          });
        },
      );
    } catch (e) {
      setState(() {
        item.status = UploadStatus.failed;
        item.statusText = 'Error: $e';
      });
    }
  }

  Widget _getStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return Icon(Icons.schedule, color: Colors.grey);
      case UploadStatus.uploading:
        return CircularProgressIndicator(strokeWidth: 2);
      case UploadStatus.completed:
        return Icon(Icons.check_circle, color: Colors.green);
      case UploadStatus.failed:
        return Icon(Icons.error, color: Colors.red);
    }
  }
}

class FileUploadItem {
  final File file;
  final String fileName;
  UploadStatus status;
  double progress;
  String statusText;

  FileUploadItem({
    required this.file,
    required this.fileName,
    required this.status,
    required this.progress,
    required this.statusText,
  });
}

enum UploadStatus { pending, uploading, completed, failed }
```

## 🔄 Stream-Based Progress Examples

### Real-time Progress Dashboard

```dart
class ProgressDashboard extends StatefulWidget {
  @override
  _ProgressDashboardState createState() => _ProgressDashboardState();
}

class _ProgressDashboardState extends State<ProgressDashboard> {
  final StreamController<ProgressData> _progressController = 
      StreamController<ProgressData>.broadcast();
  
  final List<ProgressData> _progressHistory = [];
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Real-time progress display
        StreamBuilder<ProgressData>(
          stream: _progressController.stream,
          builder: (context, snapshot) {
            final progress = snapshot.data;
            return Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Current Transfer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    if (progress != null) ...[
                      LinearProgressIndicator(
                        value: progress.percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress.isUpload ? Colors.blue : Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('${progress.type.name.toUpperCase()}: ${progress.percentage.toStringAsFixed(1)}%'),
                      Text('${(progress.sentBytes / 1024).round()} KB / ${(progress.totalBytes / 1024).round()} KB'),
                    ] else
                      Text('No active transfer'),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Progress history
        Expanded(
          child: Card(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Transfer History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _progressHistory.length,
                    itemBuilder: (context, index) {
                      final progress = _progressHistory[index];
                      return ListTile(
                        leading: Icon(
                          progress.isUpload ? Icons.upload : Icons.download,
                          color: progress.isUpload ? Colors.blue : Colors.green,
                        ),
                        title: Text('${progress.type.name.toUpperCase()}: ${progress.percentage.toStringAsFixed(1)}%'),
                        subtitle: Text('${(progress.sentBytes / 1024).round()} KB transferred'),
                        trailing: Text(DateTime.now().toString().substring(11, 19)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _startUpload,
              child: Text('Start Upload'),
            ),
            ElevatedButton(
              onPressed: _startDownload,
              child: Text('Start Download'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _startUpload() async {
    final file = await _pickFile();
    if (file == null) return;

    final result = await UploadFileAction(file)
      .withUploadProgress((progress) {
        _progressController.add(progress);
        _progressHistory.insert(0, progress);
        if (_progressHistory.length > 100) {
          _progressHistory.removeLast();
        }
      })
      .execute();
  }

  Future<void> _startDownload() async {
    final result = await DownloadFileAction('/downloads/sample.zip')
      .withDownloadProgress((progress) {
        _progressController.add(progress);
        _progressHistory.insert(0, progress);
        if (_progressHistory.length > 100) {
          _progressHistory.removeLast();
        }
      })
      .execute();
  }

  @override
  void dispose() {
    _progressController.close();
    super.dispose();
  }
}
```

## 🎯 Advanced Use Cases

### Background Upload with Notifications

```dart
class BackgroundUploadService {
  static final BackgroundUploadService _instance = BackgroundUploadService._internal();
  factory BackgroundUploadService() => _instance;
  BackgroundUploadService._internal();

  final List<UploadTask> _activeTasks = [];

  Future<void> uploadInBackground(File file, String description) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final task = UploadTask(
      id: taskId,
      fileName: file.path.split('/').last,
      totalBytes: file.lengthSync(),
    );
    
    _activeTasks.add(task);
    _showUploadStartNotification(task);

    try {
      final result = await UploadFileAction(file)
        .withUploadProgress((progress) {
          task.progress = progress.percentage;
          task.uploadedBytes = progress.sentBytes;
          
          // Update notification every 10%
          if (progress.percentage % 10 == 0) {
            _updateProgressNotification(task);
          }
        })
        .withFormData({'description': description})
        .execute();

      result?.fold(
        (error) {
          _showUploadFailedNotification(task, error.message);
        },
        (response) {
          _showUploadCompletedNotification(task);
        },
      );
    } catch (e) {
      _showUploadFailedNotification(task, e.toString());
    } finally {
      _activeTasks.remove(task);
    }
  }

  void _showUploadStartNotification(UploadTask task) {
    // Your notification service integration
    NotificationService.show(
      id: task.id.hashCode,
      title: 'Upload Started',
      body: 'Uploading ${task.fileName}...',
      progress: 0,
      ongoing: true,
    );
  }

  void _updateProgressNotification(UploadTask task) {
    NotificationService.update(
      id: task.id.hashCode,
      title: 'Uploading ${task.fileName}',
      body: '${task.progress.round()}% completed',
      progress: task.progress.round(),
      ongoing: true,
    );
  }

  void _showUploadCompletedNotification(UploadTask task) {
    NotificationService.show(
      id: task.id.hashCode,
      title: 'Upload Completed',
      body: '${task.fileName} uploaded successfully',
      ongoing: false,
      autoCancel: true,
    );
  }

  void _showUploadFailedNotification(UploadTask task, String error) {
    NotificationService.show(
      id: task.id.hashCode,
      title: 'Upload Failed',
      body: '${task.fileName}: $error',
      ongoing: false,
      autoCancel: true,
    );
  }
}

class UploadTask {
  final String id;
  final String fileName;
  final int totalBytes;
  double progress = 0.0;
  int uploadedBytes = 0;

  UploadTask({
    required this.id,
    required this.fileName,
    required this.totalBytes,
  });
}
```

### Batch Operations with Progress Aggregation

```dart
class BatchUploadManager {
  Future<void> uploadBatch(List<File> files) async {
    final totalFiles = files.length;
    int completedFiles = 0;
    int totalBytes = files.fold(0, (sum, file) => sum + file.lengthSync());
    int uploadedBytes = 0;

    print('Starting batch upload of $totalFiles files (${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB)');

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = file.path.split('/').last;
      
      print('Uploading file ${i + 1}/$totalFiles: $fileName');

      try {
        final result = await UploadSingleFileAction(file)
          .withUploadProgress((progress) {
            // Calculate overall batch progress
            final currentFileBytes = progress.sentBytes;
            final overallProgress = ((uploadedBytes + currentFileBytes) / totalBytes) * 100;
            
            print('File ${i + 1}: ${progress.percentage.toStringAsFixed(1)}% | Batch: ${overallProgress.toStringAsFixed(1)}%');
          })
          .execute();

        result?.fold(
          (error) {
            print('Failed to upload $fileName: ${error.message}');
          },
          (response) {
            completedFiles++;
            uploadedBytes += file.lengthSync();
            print('Successfully uploaded $fileName ($completedFiles/$totalFiles completed)');
          },
        );
      } catch (e) {
        print('Error uploading $fileName: $e');
      }
    }

    print('Batch upload completed: $completedFiles/$totalFiles files uploaded');
  }
}
```

### Performance Analytics with Progress Data

```dart
class ProgressAnalytics {
  static void analyzeTransferPerformance() {
    final performance = ApiRequestPerformance.instance;
    final reports = performance?.actionsReport.values
        .where((report) => report?.hasProgressData == true)
        .toList() ?? [];

    if (reports.isEmpty) {
      print('No transfer data available for analysis');
      return;
    }

    print('\n=== Transfer Performance Analysis ===');
    
    // Overall statistics
    final totalRequests = reports.length;
    final totalBytes = reports.fold(0, (sum, report) => sum + (report?.bytesTransferred ?? 0));
    final avgTransferRate = reports
        .map((report) => report?.transferRate ?? 0.0)
        .reduce((a, b) => a + b) / reports.length;

    print('Total requests with transfer data: $totalRequests');
    print('Total bytes transferred: ${_formatBytes(totalBytes)}');
    print('Average transfer rate: ${_formatTransferRate(avgTransferRate)}');

    // Upload vs Download analysis
    final uploadBytes = reports.fold(0, (sum, report) => sum + (report?.uploadBytes ?? 0));
    final downloadBytes = reports.fold(0, (sum, report) => sum + (report?.downloadBytes ?? 0));
    
    print('\nUpload vs Download:');
    print('Upload: ${_formatBytes(uploadBytes)} (${(uploadBytes / totalBytes * 100).toStringAsFixed(1)}%)');
    print('Download: ${_formatBytes(downloadBytes)} (${(downloadBytes / totalBytes * 100).toStringAsFixed(1)}%)');

    // Performance insights
    print('\n=== Performance Insights ===');
    
    // Find slowest transfers
    final sortedByRate = List.from(reports)
      ..sort((a, b) => (a?.transferRate ?? 0.0).compareTo(b?.transferRate ?? 0.0));
    
    print('Slowest transfers:');
    sortedByRate.take(3).forEach((report) {
      print('  ${report?.actionName}: ${_formatTransferRate(report?.transferRate ?? 0.0)} - ${_formatBytes(report?.bytesTransferred ?? 0)}');
    });

    print('Fastest transfers:');
    sortedByRate.reversed.take(3).forEach((report) {
      print('  ${report?.actionName}: ${_formatTransferRate(report?.transferRate ?? 0.0)} - ${_formatBytes(report?.bytesTransferred ?? 0)}');
    });

    // Duration vs Transfer size correlation
    print('\nDuration vs Transfer Size:');
    reports.forEach((report) {
      final duration = report?.duration?.inMilliseconds ?? 0;
      final bytes = report?.bytesTransferred ?? 0;
      if (duration > 0 && bytes > 0) {
        print('  ${report?.actionName}: ${duration}ms for ${_formatBytes(bytes)}');
      }
    });
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)}MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)}GB';
  }

  static String _formatTransferRate(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.toStringAsFixed(1)}B/s';
    if (bytesPerSecond < 1024 * 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)}KB/s';
    return '${(bytesPerSecond / 1024 / 1024).toStringAsFixed(1)}MB/s';
  }
}
```

## 🧪 Testing Examples

### Testing Progress Callbacks

```dart
void main() {
  group('Progress Tracking Tests', () {
    test('should call progress handler during upload', () async {
      bool progressCalled = false;
      double lastProgress = -1;
      
      final result = await MockUploadAction(testFile)
        .withUploadProgress((progress) {
          progressCalled = true;
          expect(progress.percentage, greaterThanOrEqualTo(lastProgress));
          expect(progress.sentBytes, greaterThanOrEqualTo(0));
          expect(progress.totalBytes, greaterThan(0));
          expect(progress.isUpload, isTrue);
          lastProgress = progress.percentage;
        })
        .execute();
        
      expect(progressCalled, isTrue);
      expect(lastProgress, equals(100.0));
    });

    test('should track both upload and download progress', () async {
      bool uploadProgressCalled = false;
      bool downloadProgressCalled = false;
      
      final result = await MockUploadAction(testFile)
        .withUploadProgress((progress) {
          uploadProgressCalled = true;
          expect(progress.isUpload, isTrue);
        })
        .withDownloadProgress((progress) {
          downloadProgressCalled = true;
          expect(progress.isDownload, isTrue);
        })
        .execute();
        
      expect(uploadProgressCalled, isTrue);
      expect(downloadProgressCalled, isTrue);
    });

    test('should handle progress errors gracefully', () async {
      bool requestCompleted = false;
      
      final result = await MockUploadAction(testFile)
        .withProgress((progress) {
          // Simulate error in progress handler
          throw Exception('Progress handler error');
        })
        .execute();
        
      // Request should still complete despite progress handler error
      result?.fold(
        (error) => fail('Request should not fail due to progress handler error'),
        (response) => requestCompleted = true,
      );
      
      expect(requestCompleted, isTrue);
    });
  });
}
```

This comprehensive examples file demonstrates real-world usage patterns for the progress tracking system across different scenarios, from simple UI integration to complex batch operations and performance analytics.
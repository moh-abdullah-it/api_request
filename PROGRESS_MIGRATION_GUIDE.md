# Progress Tracking Migration Guide

This guide helps you add progress tracking to existing API request actions and migrate to the unified progress system introduced in version 1.1.0.

## 📋 Overview

The progress tracking system provides:
- **Unified progress data structure** across all request types
- **Backward compatibility** with existing progress implementations
- **Enhanced performance monitoring** with transfer data
- **Fluent API design** for easy integration

## 🔄 Migration Scenarios

### 1. Adding Progress to Existing RequestActions

#### Before (No Progress Tracking)
```dart
class CreatePostAction extends RequestAction<Post, CreatePostRequest> {
  CreatePostAction(CreatePostRequest request) : super(request);

  @override
  String get path => '/posts';
  
  @override
  RequestMethod get method => RequestMethod.POST;
  
  @override
  ResponseBuilder<Post> get responseBuilder => (data) => Post.fromJson(data);
}

// Usage
final result = await CreatePostAction(request).execute();
```

#### After (With Progress Tracking)
```dart
// Same action class - no changes needed!
class CreatePostAction extends RequestAction<Post, CreatePostRequest> {
  CreatePostAction(CreatePostRequest request) : super(request);

  @override
  String get path => '/posts';
  
  @override
  RequestMethod get method => RequestMethod.POST;
  
  @override
  ResponseBuilder<Post> get responseBuilder => (data) => Post.fromJson(data);
}

// Usage - just add progress handlers
final result = await CreatePostAction(request)
  .withProgress((progress) {
    print('${progress.type.name}: ${progress.percentage}%');
    updateProgressBar(progress.percentage);
  })
  .execute();

// Or separate upload/download tracking
final result = await CreatePostAction(request)
  .withUploadProgress((progress) {
    print('Uploading: ${progress.percentage}%');
    updateUploadUI(progress.percentage);
  })
  .withDownloadProgress((progress) {
    print('Processing: ${progress.percentage}%');
    updateDownloadUI(progress.percentage);
  })
  .execute();
```

### 2. Migrating SimpleApiRequest Usage

#### Before (Direct Dio Progress Callbacks)
```dart
final client = SimpleApiRequest.init();
final result = await client.post<Post>(
  '/posts',
  data: postData,
  onSendProgress: (sent, total) {
    final percentage = (sent / total * 100).round();
    print('Upload: $percentage%');
  },
  onReceiveProgress: (received, total) {
    final percentage = (received / total * 100).round();
    print('Download: $percentage%');
  },
);
```

#### After (Unified Progress System)
```dart
final client = SimpleApiRequest.init()
  .withProgress((progress) {
    print('${progress.type.name}: ${progress.percentage.toStringAsFixed(1)}%');
    print('${progress.sentBytes}/${progress.totalBytes} bytes');
    
    if (progress.isUpload) {
      updateUploadUI(progress);
    } else if (progress.isDownload) {
      updateDownloadUI(progress);
    }
  });

// Progress is automatically applied to all requests
final result = await client.post<Post>('/posts', data: postData);
```

### 3. Migrating FileDownloadAction

#### Before (Legacy Progress Callback)
```dart
class DownloadDocumentAction extends FileDownloadAction {
  DownloadDocumentAction(String savePath) : super(savePath);
  
  @override
  String get path => '/documents/{id}/download';
}

// Usage with legacy progress
final result = await DownloadDocumentAction('/downloads/doc.pdf')
  .where('id', documentId)
  .onProgress((received, total) {
    final percentage = (received / total * 100).round();
    updateProgressBar(percentage);
  })
  .execute();
```

#### After (Unified Progress System + Backward Compatible)
```dart
// Same action class - no changes needed!
class DownloadDocumentAction extends FileDownloadAction {
  DownloadDocumentAction(String savePath) : super(savePath);
  
  @override
  String get path => '/documents/{id}/download';
}

// Option 1: Keep legacy progress (still works)
final result = await DownloadDocumentAction('/downloads/doc.pdf')
  .where('id', documentId)
  .onProgress((received, total) {
    final percentage = (received / total * 100).round();
    updateProgressBar(percentage);
  })
  .execute();

// Option 2: Use new unified progress
final result = await DownloadDocumentAction('/downloads/doc.pdf')
  .where('id', documentId)
  .withDownloadProgress((progress) {
    updateProgressBar(progress.percentage);
    
    if (progress.isCompleted) {
      showCompletionNotification();
    }
  })
  .execute();

// Option 3: Use both systems together
final result = await DownloadDocumentAction('/downloads/doc.pdf')
  .where('id', documentId)
  .onProgress((received, total) => updateLegacyUI(received, total))
  .withDownloadProgress((progress) => updateModernUI(progress))
  .execute();
```

### 4. Adding File Upload Capabilities

#### Before (Custom Upload Logic)
```dart
// Custom implementation needed for file uploads
class CustomUploadService {
  Future<Either<Error, User>> uploadAvatar(File file) async {
    final client = RequestClient.instance;
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromFileSync(file.path),
      'description': 'Profile photo',
    });
    
    try {
      final response = await client?.dio.post('/users/avatar', data: formData);
      return right(User.fromJson(response?.data));
    } catch (e) {
      return left(ActionRequestError(e));
    }
  }
}
```

#### After (Dedicated FileUploadAction)
```dart
class UploadAvatarAction extends FileUploadAction<User> {
  UploadAvatarAction(File avatarFile) : super({'avatar': avatarFile});

  @override
  String get path => '/users/avatar';

  @override
  ResponseBuilder<User> get responseBuilder => (data) => User.fromJson(data);
}

// Usage with progress tracking
final result = await UploadAvatarAction(avatarFile)
  .withUploadProgress((progress) {
    setState(() {
      uploadProgress = progress.percentage;
    });
    
    if (progress.isCompleted) {
      showSnackBar('Upload completed!');
    }
  })
  .withFormData({
    'description': 'Profile photo',
  })
  .execute();
```

## 🎯 Best Practices for Migration

### 1. Gradual Migration Approach

**Phase 1: Add Progress to New Actions**
```dart
// Start with new actions
class NewFeatureAction extends RequestAction<Data, Request> {
  // ... implementation
}

// Add progress from day one
final result = await NewFeatureAction(request)
  .withProgress((progress) => updateUI(progress))
  .execute();
```

**Phase 2: Enhance Existing Critical Actions**
```dart
// Update critical user-facing actions
final result = await ImportantUserAction(request)
  .withProgress((progress) {
    // Add progress UI for better UX
    showProgressDialog(progress);
  })
  .execute();
```

**Phase 3: Migrate FileDownloadAction (Optional)**
```dart
// Optionally migrate to unified system
.withDownloadProgress((progress) => updateUI(progress))
// Keep legacy if it works fine
.onProgress((received, total) => updateLegacyUI(received, total))
```

### 2. Testing Migration

**Test Both Systems During Migration**
```dart
class TestAction extends RequestAction<Data, Request> {
  // ... implementation
}

void testProgressMigration() async {
  bool legacyProgressCalled = false;
  bool unifiedProgressCalled = false;
  
  final result = await TestAction(request)
    .withProgress((progress) {
      unifiedProgressCalled = true;
      assert(progress.percentage >= 0 && progress.percentage <= 100);
      assert(progress.sentBytes >= 0);
      assert(progress.totalBytes >= 0);
    })
    .execute();
    
  assert(unifiedProgressCalled, 'Unified progress should be called');
}
```

### 3. Performance Monitoring Migration

**Before (Basic Performance)**
```dart
final report = action.performanceReport;
if (report != null) {
  print('Duration: ${report.duration}');
}
```

**After (Enhanced Performance with Transfer Data)**
```dart
final report = action.performanceReport;
if (report != null) {
  print('Duration: ${report.duration}');
  
  // New transfer data available
  if (report.hasProgressData) {
    print('Uploaded: ${report.uploadBytes} bytes');
    print('Downloaded: ${report.downloadBytes} bytes');
    print('Transfer rate: ${report.transferRate} bytes/sec');
  }
}
```

## 🔧 Common Migration Patterns

### Pattern 1: Simple Progress Addition
```dart
// Before
await action.execute();

// After
await action
  .withProgress((progress) => print('${progress.percentage}%'))
  .execute();
```

### Pattern 2: UI Integration
```dart
class ProgressAwareWidget extends StatefulWidget {
  @override
  _ProgressAwareWidgetState createState() => _ProgressAwareWidgetState();
}

class _ProgressAwareWidgetState extends State<ProgressAwareWidget> {
  double _progress = 0.0;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(value: _progress / 100),
        ElevatedButton(
          onPressed: _startRequest,
          child: Text('Start Request'),
        ),
      ],
    );
  }
  
  Future<void> _startRequest() async {
    final result = await SomeAction(request)
      .withProgress((progress) {
        setState(() {
          _progress = progress.percentage;
        });
      })
      .execute();
  }
}
```

### Pattern 3: Stream-Based Integration
```dart
class StreamProgressWidget extends StatefulWidget {
  @override
  _StreamProgressWidgetState createState() => _StreamProgressWidgetState();
}

class _StreamProgressWidgetState extends State<StreamProgressWidget> {
  final _progressController = StreamController<ProgressData>.broadcast();
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProgressData>(
      stream: _progressController.stream,
      builder: (context, snapshot) {
        final progress = snapshot.data;
        return CircularProgressIndicator(
          value: progress != null ? progress.percentage / 100 : 0,
        );
      },
    );
  }
  
  Future<void> executeWithStreamProgress() async {
    final result = await SomeAction(request)
      .withProgress((progress) {
        _progressController.add(progress);
      })
      .execute();
  }
}
```

## 🚨 Migration Gotchas

### 1. Progress Handler Errors
```dart
// ❌ Don't let progress handlers throw errors
.withProgress((progress) {
  someMethodThatMightThrow(); // This could break the request
})

// ✅ Handle errors in progress handlers
.withProgress((progress) {
  try {
    updateUI(progress);
  } catch (e) {
    print('Progress UI update failed: $e');
  }
})
```

### 2. Memory Leaks with Streams
```dart
// ❌ Don't forget to close stream controllers
final controller = StreamController<ProgressData>();
// ... use controller ...
// Missing: controller.close();

// ✅ Properly manage stream lifecycle
final controller = StreamController<ProgressData>();
try {
  // ... use controller ...
} finally {
  await controller.close();
}
```

### 3. Performance with Frequent Updates
```dart
// ❌ Heavy operations in progress handlers
.withProgress((progress) {
  performExpensiveCalculation(); // Called frequently!
  updateComplexUI();
})

// ✅ Throttle or optimize progress handlers
DateTime? lastUpdate;
.withProgress((progress) {
  final now = DateTime.now();
  if (lastUpdate == null || now.difference(lastUpdate!) > Duration(milliseconds: 100)) {
    updateUI(progress);
    lastUpdate = now;
  }
})
```

## 📚 Additional Resources

- [Progress Tracking API Reference](https://pub.dev/documentation/api_request/latest/api_request/ProgressData-class.html)
- [FileUploadAction Documentation](https://pub.dev/documentation/api_request/latest/api_request/FileUploadAction-class.html)
- [Performance Monitoring Guide](https://pub.dev/documentation/api_request/latest/api_request/ApiRequestPerformance-class.html)
- [Complete Example App](example/) with progress tracking demonstrations

## 🤝 Migration Support

If you encounter issues during migration:

1. **Check Compatibility**: All existing code should work without changes
2. **Review Examples**: See the example app for working implementations
3. **Open Issues**: Report problems on [GitHub Issues](https://github.com/moh-abdullah-it/api_request/issues)
4. **Community Support**: Ask questions in [GitHub Discussions](https://github.com/moh-abdullah-it/api_request/discussions)

Remember: **Migration is optional and incremental**. Your existing code will continue to work, and you can add progress tracking features at your own pace.
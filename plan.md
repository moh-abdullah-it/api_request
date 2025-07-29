# Progress Tracking Feature - Implementation Plan

## Overview
Add progress tracking capabilities to the API request system, allowing users to monitor the progress of HTTP requests, especially useful for file uploads, downloads, and long-running operations.

## Architecture Design

### 1. Progress Callback Interface
```dart
/// Function type for handling request progress updates
typedef ProgressHandler = void Function(ProgressData progress);

/// Data class containing progress information
class ProgressData {
  final int sentBytes;
  final int totalBytes;
  final double percentage;
  final ProgressType type;
  
  const ProgressData({
    required this.sentBytes,
    required this.totalBytes,
    required this.percentage,
    required this.type,
  });
}

enum ProgressType {
  upload,
  download,
}
```

### 2. Integration Points

#### RequestAction Base Class Enhancements
- Add `ProgressHandler? onProgress` callback property
- Add `withProgress(ProgressHandler handler)` method for fluent API
- Integrate progress callbacks with Dio's `onSendProgress` and `onReceiveProgress`

#### RequestClient Modifications
- Update HTTP methods (get, post, put, delete) to support progress callbacks
- Pass progress handlers to Dio's Options configuration
- Handle both upload and download progress tracking

### 3. Implementation Strategy

#### Phase 1: Core Progress Infrastructure ✅ COMPLETED
1. ✅ Create `ProgressData` class and `ProgressHandler` typedef
2. ✅ Add progress callback properties to `RequestAction` base class
3. ✅ Implement fluent API methods (`withProgress`, `withUploadProgress`, `withDownloadProgress`)

**Phase 1 Status**: COMPLETED
- Created `/src/progress/progress_data.dart` with `ProgressData` class and `ProgressType` enum
- Created `/src/progress/progress_handler.dart` with progress handler typedefs
- Added progress callback properties to `RequestAction` base class
- Implemented fluent API methods with comprehensive documentation
- Updated main export file to include progress functionality
- All code compiles successfully with no errors

#### Phase 2: HTTP Client Integration ✅ COMPLETED
1. ✅ Modify `RequestClient` to accept progress callbacks
2. ✅ Update all HTTP method implementations (get, post, put, delete)
3. ✅ Wire progress callbacks to Dio's native progress tracking

**Phase 2 Status**: COMPLETED
- Added progress callback helper methods to `RequestAction` base class
- Updated GET method with `onReceiveProgress` callback support
- Updated POST method with both `onSendProgress` and `onReceiveProgress` callback support
- Updated PUT method with both `onSendProgress` and `onReceiveProgress` callback support
- DELETE method documented as not supporting progress (Dio limitation)
- Added `_hasProgressHandlers` getter to optimize callback registration
- Added `_onSendProgress` and `_onReceiveProgress` methods to convert Dio callbacks to `ProgressData`
- Integrated with existing `_handleProgress` method for handler propagation
- All HTTP methods now support progress tracking where Dio allows it
- Code compiles successfully with no errors

#### Phase 3: Lifecycle Integration
1. Integrate progress callbacks with existing lifecycle hooks
2. Ensure progress callbacks work with both `execute()` and `onQueue()` methods
3. Add progress support to streaming operations

**Update plan.md after Phase 3 completion**

#### Phase 4: Enhanced Features
1. Add progress tracking to `SimpleApiRequest` utility class
2. Create specialized progress actions for file operations
3. Add progress reporting to performance monitoring system

**Update plan.md after Phase 4 completion**

### 4. API Design Examples

#### Basic Progress Tracking
```dart
final result = await CreatePostAction(request)
  .withProgress((progress) {
    print('Upload progress: ${progress.percentage}%');
    updateProgressBar(progress.percentage);
  })
  .execute();
```

#### Separate Upload/Download Progress
```dart
final result = await FileUploadAction(file)
  .withUploadProgress((progress) {
    print('Uploading: ${progress.percentage}%');
  })
  .withDownloadProgress((progress) {
    print('Processing: ${progress.percentage}%');
  })
  .execute();
```

#### Stream-based Progress
```dart
action
  .withProgress((progress) => progressController.add(progress))
  .subscribe(
    onSuccess: (data) => handleSuccess(data),
    onError: (error) => handleError(error),
  )
  .onQueue();
```

### 5. File Structure Changes

```
lib/src/
├── actions/
│   ├── api_request_action.dart       # Add progress support
│   ├── request_action.dart           # Core progress implementation
│   └── file_download_action.dart     # Enhanced with progress
├── progress/                         # New directory
│   ├── progress_data.dart           # Progress data structures
│   └── progress_handler.dart        # Progress callback types
├── api_request_client.dart          # Update HTTP methods
└── simple_api_request.dart          # Add progress methods
```

### 6. Backward Compatibility
- All progress features are optional (callbacks default to null)
- Existing API remains unchanged
- No breaking changes to current functionality
- Progressive enhancement approach

### 7. Testing Strategy
- Unit tests for progress data calculations
- Integration tests with mock HTTP requests
- Tests for both upload and download scenarios
- Performance impact testing
- Stream-based progress testing

### 8. Documentation Updates
- Update README with progress tracking examples
- Add progress-specific dartdoc comments
- Create migration guide for adding progress to existing actions
- Example implementations for common use cases

## Implementation Priority
1. **High Priority**: Core progress infrastructure and basic callback support
2. **Medium Priority**: Full HTTP client integration and lifecycle hooks
3. **Low Priority**: Enhanced features and specialized actions

## Success Criteria
- Zero breaking changes to existing API
- Progress callbacks work with all HTTP methods
- Both upload and download progress supported
- Integration with existing error handling and lifecycle
- Comprehensive test coverage
- Clear documentation and examples
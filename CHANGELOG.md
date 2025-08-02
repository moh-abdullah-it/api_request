## 1.5.1
* 🐛 **FIX**: Integrate `path_provider_foundation` and disable ANSI colors on iOS
* 🐛 **FIX**: Replace `print` with `debugPrint` for improved logging consistency
* 🔧 **ENHANCED**: Resolved miscellaneous code formatting inconsistencies across multiple files for cleaner readability and structure

## 1.5.0
* 🎨 **NEW**: Complete visual overhaul of API request/response logging with beautiful colored output
* ✨ **NEW**: JSON syntax highlighting with cyan keys, green strings, yellow numbers, and magenta booleans
* 🌈 **NEW**: Color-coded HTTP methods (GET=blue, POST=green, DELETE=red, PUT=yellow, PATCH=magenta)
* 📊 **NEW**: Status code aware coloring (2xx=green, 3xx=yellow, 4xx=red, 5xx=bright red)
* 🎯 **NEW**: Structured color themes - cyan for requests, green for responses, red for errors
* 🔧 **NEW**: `LogColors` utility class with 30+ ANSI color methods and smart detection
* 📝 **NEW**: `JsonFormatter` with intelligent key detection and proper indentation
* 🔧 **ENHANCED**: Completely redesigned console output with professional formatting and visual hierarchy
* 🔧 **ENHANCED**: Better handling of large JSON responses with proper syntax highlighting
* ⚙️ **TECHNICAL**: Colors automatically disabled in release mode for performance
* ⚙️ **TECHNICAL**: Graceful fallback to plain text when colors not supported
* 🔄 **COMPATIBILITY**: 100% backward compatible - existing logging configurations unchanged

## 1.4.0
* 🎉 **NEW**: Introduced `ApiLogLevel` enum for granular logging control (none, error, info, debug)
* ✨ **NEW**: `ApiLogLevel.debug` - Send logs only to custom `onLog` callback (no console output)
* ✨ **NEW**: `ApiLogLevel.error` - Log only API errors and exceptions to console
* ✨ **NEW**: `ApiLogLevel.info` - Full request/response logging to console (default behavior)
* ✨ **NEW**: `ApiLogLevel.none` - Disable all logging completely
* 🔧 **ENHANCED**: Dual logging support - custom `onLog` callbacks work alongside console output
* 🔧 **ENHANCED**: `ApiLogData` includes comprehensive request/response metadata and timing information
* 📚 **DOCS**: Added complete logging documentation with file logging, error monitoring, and performance tracking examples
* 🗑️ **DEPRECATED**: `enableLog` parameter deprecated in favor of `logLevel` (still works for backward compatibility)
* 🔄 **COMPATIBILITY**: 100% backward compatible - existing code continues to work unchanged

## 1.3.0
* 🎉 **NEW**: Unified progress tracking system with `ProgressData` and `ProgressHandler`
* ✨ **NEW**: `FileUploadAction<T>` for file uploads with progress tracking
* ✨ **NEW**: Enhanced `SimpleApiRequest` with `.withProgress()`, `.withUploadProgress()`, `.withDownloadProgress()`
* 🔧 **ENHANCED**: Performance monitoring now includes transfer data and rates
* 🔧 **ENHANCED**: All request types support progress tracking
* 📚 **DOCS**: Added comprehensive progress examples and migration guide
* 🔄 **COMPATIBILITY**: 100% backward compatible

## 1.2.0
* 🎉 **NEW**: Added comprehensive file download support with `FileDownloadAction`
* ✨ **NEW**: Progress tracking with callbacks and reactive streams for file downloads
* ✨ **NEW**: Cancellation support for download operations using `CancelToken`
* ✨ **NEW**: `DownloadProgress` class with formatted progress reporting
* ✨ **NEW**: Stream-based progress monitoring for real-time download updates
* 🔧 **ENHANCED**: `SimpleApiRequest` download method already supported file downloads
* 📚 **DOCS**: Updated README with comprehensive file download examples and usage patterns
* 📚 **DOCS**: Added file download documentation to features and core components sections

## 1.1.1
* Enhanced comprehensive dartdoc documentation across all library files
* Added detailed class-level documentation for ApiResource with usage examples and comparison guidance
* Added extensive documentation for SimpleApiRequest covering all HTTP methods, factory constructors, and error handling patterns
* Enhanced ApiRequestUtils with complete method documentation and path variable resolution examples
* Improved documentation consistency with cross-references, parameter descriptions, and return value explanations
* Added migration guidance and best practices throughout the codebase
* Enhanced code examples with real-world usage patterns and error handling demonstrations

## 1.1.0
* Completely rewrote README.md with modern structure and comprehensive documentation
* Added professional header with badges and clear feature highlights
* Included step-by-step quick start guide with better code examples
* Added advanced usage patterns for dynamic paths, multi-environment support, and error handling
* Enhanced architecture overview and testing examples
* Added links to example app and comprehensive documentation
* Fixed flutter_lints dependency issue in example app

## 1.0.9
* add `withHeader`, `withHeaders` to add action headers in runtime.

## 1.0.8
* change execute return to `Either<ActionRequestError?, T?>?` may be return null

## 1.0.7
* add `whereQuery`, `whereMapQuery` to build query builder
* add `where`, `whereMap` to request data

## 1.0.6
* print form data in log

## 1.0.5
* fix request action if token is null

## 1.0.4
* fix Unsupported operation: Cannot modify unmodifiable map

## 1.0.3
* add `where` to Query Builder

## 1.0.2
* add `disableGlobalOnError` to disable global error tracking

## 1.0.1
* remove api error from `ApiRequestAction`

## 1.0.0
* upgrade `dependencies`
## 1.0.0-pre-7
* modify `ActionRequestError` catch and handle errors
* modify `execute` to handle response with errors
* mark Deprecated to `run` method
* mark Deprecated to `ApiRequestException` method
* Upgrade dart 2.19 with flutter 3.7

## 1.0.0-pre-6
* modify `refreshConfig` to update config after change 
* modify `SimpleApiRequest`

## 1.0.0-pre-5
* modify default headers to options

## 1.0.0-pre-4
* fix return response when status code not success

## 1.0.0-pre-3
* modify `run` method use Either `ApiRequestAction`
* modify `ApiRequestException` to handle api server errors

## 1.0.0-pre-2
* modify `listFormat` global option in `ApiRequestOptions`

## 1.0.0-pre-1
* modify `onError` global error handler in `ApiRequestOptions`

## 0.8.5
* modify `ApiRequestError` to to dynamic error
* modify `subscribe` to call `execute` or `onQueue`

## 0.8.0
* add `ApiRequestPerformance` to extract performance report
* convert events to `getter`, `setter` to access its from any where

## 0.7.2
* modify `ApiRequestError` by use try catch

## 0.7.1
* update documentation

## 0.7.0
* add `ApiRequestAction` for simple api request don't need to `ApiRequest` class
* rename `onChnage` to `subscribe`
* merge `defaultQueryParameters` with old instance
* merge `interceptors` with old instance
* add more to `ApiRequestOptions`:
    * connectionTimeOut
    * interceptors
    * enableLog

## 0.5.3
* fix typing error

## 0.5.2
* modify token type api request options

## 0.5.1
* fix execute return type

## 0.5.0
* you can access stream if action run onQueue
* fix run package in web
* use dio instance
* dispose action after success or error

## 0.1.2
* fix run in mobile
* reverse support web

## 0.1.1
* fix support web

## 0.1.0
* refactor `RequestAction`
* add `onQueue`
* listen to action `onInit`, `onStart`, `onSuccess`, `onError`
* add `ApiRequestError`
* add `onChange` to subscribe to stream

## 0.0.6
* add Token to Header by Interceptors

## 0.0.5
* add contentDataType for request
* convert `ApiRequest` to `mixin`

## 0.0.4
* add dynamic path
  
## 0.0.3+1
* update change log

## 0.0.3
* improve document
* add more example

## 0.0.2
* first release for flutter api request as action

## 0.0.1
* TODO: Describe initial release.

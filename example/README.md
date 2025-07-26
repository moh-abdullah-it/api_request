# API Request Package Example

A comprehensive example Flutter app demonstrating the API Request package features.

## Features Demonstrated

- **CRUD Operations**: Full create, read, update, delete operations for posts
- **File Downloads**: Multiple approaches to downloading files with progress tracking
- **Error Handling**: Comprehensive error handling patterns
- **Performance Monitoring**: Built-in request performance tracking
- **Mock vs Live API**: Toggle between mock data and live API calls

## File Download Features

This example showcases the file download capabilities:

- Action-based downloads using `FileDownloadAction`
- Direct downloads using `SimpleApiRequest`
- Progress tracking with visual indicators
- Stream-based progress monitoring
- Download cancellation support
- File management (view, delete downloaded files)

## Platform Permissions

The app is configured with the necessary permissions for network access and file storage:

### macOS
- Network client access for API calls
- File system access for downloads (user-selected and downloads folder)
- App Transport Security configured for HTTP requests

### iOS
- App Transport Security configured for HTTP requests

### Android
- Internet permission for network access
- External storage read/write permissions for file downloads

## Getting Started

1. Install dependencies:
   ```bash
   flutter packages get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

3. Navigate between the "Posts" and "Downloads" tabs to explore different features

## Configuration

The app can be configured to use mock data or live API calls by modifying `AppConfig.useMockData` in `lib/config/app_config.dart`.

## API Request Package Documentation

For complete documentation of the API Request package, visit the [main README](../README.md).

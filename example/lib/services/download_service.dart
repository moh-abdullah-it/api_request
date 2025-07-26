import 'dart:io';
import 'package:api_request/api_request.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';

/// Service class to handle all file download operations
class DownloadService {
  /// Download a sample PDF file
  static Future<Either<ActionRequestError, String>?> downloadSamplePdf() async {
    final savePath = await _getSavePath('sample_document.pdf');
    final action = DownloadPdfAction(savePath);
    final result = await action.execute();

    return result?.fold(
      (error) => left(error),
      (response) => right(savePath),
    );
  }

  /// Download a sample image file
  static Future<Either<ActionRequestError, String>?>
      downloadSampleImage() async {
    final savePath = await _getSavePath('sample_image.jpg');
    final action = DownloadImageAction(savePath);
    final result = await action.execute();

    return result?.fold(
      (error) => left(error),
      (response) => right(savePath),
    );
  }

  /// Download file using SimpleApiRequest (direct approach)
  static Future<Response?> downloadWithProgress(
    String url,
    String fileName,
    Function(int received, int total)? onProgress,
  ) async {
    final savePath = await _getSavePath(fileName);
    final client = SimpleApiRequest.init();

    return await client.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
    );
  }

  /// Get the path where files will be saved
  static Future<String> _getSavePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${directory.path}/downloads');

    // Create downloads directory if it doesn't exist
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    return '${downloadDir.path}/$fileName';
  }

  /// Check if a downloaded file exists
  static Future<bool> fileExists(String fileName) async {
    final savePath = await _getSavePath(fileName);
    return File(savePath).exists();
  }

  /// Get the full path for a downloaded file
  static Future<String> getFilePath(String fileName) async {
    return await _getSavePath(fileName);
  }

  /// Delete a downloaded file
  static Future<bool> deleteFile(String fileName) async {
    try {
      final savePath = await _getSavePath(fileName);
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get list of all downloaded files
  static Future<List<String>> getDownloadedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');

      if (!await downloadDir.exists()) {
        return [];
      }

      final files = await downloadDir.list().toList();
      return files
          .whereType<File>()
          .map((file) => file.path.split('/').last)
          .toList();
    } catch (e) {
      return [];
    }
  }
}

/// Action to download a PDF document
class DownloadPdfAction extends FileDownloadAction {
  DownloadPdfAction(String savePath) : super(savePath);

  @override
  String get path =>
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';

  @override
  bool get authRequired => false;
}

/// Action to download an image
class DownloadImageAction extends FileDownloadAction {
  DownloadImageAction(String savePath) : super(savePath);

  @override
  String get path => 'https://picsum.photos/800/600';

  @override
  bool get authRequired => false;
}

/// Action to download a large file (for testing progress)
class DownloadLargeFileAction extends FileDownloadAction {
  DownloadLargeFileAction(String savePath) : super(savePath);

  @override
  String get path =>
      'https://file-examples.com/storage/fe97b7ea52bbf93bac98076/2017/10/file_example_JPG_2500kB.jpg';

  @override
  bool get authRequired => false;
}

/// Action to download a file with custom parameters
class DownloadCustomFileAction extends FileDownloadAction {
  DownloadCustomFileAction(String savePath) : super(savePath);

  @override
  String get path => 'files/{fileId}';

  @override
  bool get authRequired => false;
}

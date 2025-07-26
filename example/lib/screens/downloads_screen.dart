import 'dart:async';

import 'package:api_request/api_request.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:flutter/material.dart';
import '../services/download_service.dart';
import '../widgets/download_progress_card.dart';

/// Screen demonstrating file download capabilities using the API Request package
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final Map<String, bool> _downloadingStatus = {};
  final Map<String, double> _downloadProgress = {};
  final Map<String, String> _downloadErrors = {};
  final Map<String, StreamSubscription> _progressSubscriptions = {};

  @override
  void dispose() {
    // Cancel all progress subscriptions
    for (final subscription in _progressSubscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }

  /// Download sample PDF using action-based approach
  Future<void> _downloadSamplePdf() async {
    const fileName = 'sample_document.pdf';
    await _downloadWithAction(
      fileName: fileName,
      downloadFunction: () => DownloadService.downloadSamplePdf(),
      title: 'Sample PDF Document',
    );
  }

  /// Download sample image using action-based approach
  Future<void> _downloadSampleImage() async {
    const fileName = 'sample_image.jpg';
    await _downloadWithAction(
      fileName: fileName,
      downloadFunction: () => DownloadService.downloadSampleImage(),
      title: 'Sample Image',
    );
  }

  /// Download large file with progress tracking using action-based approach
  Future<void> _downloadLargeFileWithProgress() async {
    const fileName = 'large_sample.jpg';
    
    setState(() {
      _downloadingStatus[fileName] = true;
      _downloadProgress[fileName] = 0.0;
      _downloadErrors.remove(fileName);
    });

    try {
      final savePath = await DownloadService.getFilePath(fileName);
      final action = DownloadLargeFileAction(savePath);
      
      // Listen to progress stream
      final subscription = action.progressStream.listen(
        (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress[fileName] = progress.received / progress.total;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _downloadingStatus[fileName] = false;
              _downloadErrors[fileName] = error.toString();
            });
          }
        },
      );
      
      _progressSubscriptions[fileName] = subscription;

      // Configure progress callback
      action.onProgress((received, total) {
        if (mounted && total > 0) {
          setState(() {
            _downloadProgress[fileName] = received / total;
          });
        }
      });

      final result = await action.execute();
      
      await subscription.cancel();
      _progressSubscriptions.remove(fileName);

      if (mounted) {
        setState(() {
          _downloadingStatus[fileName] = false;
        });

        result?.fold(
          (error) {
            setState(() {
              _downloadErrors[fileName] = error.message ?? 'Download failed';
            });
            _showErrorSnackBar('Failed to download large file: ${error.message}');
          },
          (response) {
            _downloadProgress[fileName] = 1.0;
            _showSuccessSnackBar('Large file downloaded successfully!');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingStatus[fileName] = false;
          _downloadErrors[fileName] = e.toString();
        });
        _showErrorSnackBar('Download error: $e');
      }
    }
  }

  /// Download file using SimpleApiRequest (direct approach) with progress
  Future<void> _downloadWithSimpleApiRequest() async {
    const fileName = 'direct_download.jpg';
    
    setState(() {
      _downloadingStatus[fileName] = true;
      _downloadProgress[fileName] = 0.0;
      _downloadErrors.remove(fileName);
    });

    try {
      final response = await DownloadService.downloadWithProgress(
        'https://picsum.photos/1200/800',
        fileName,
        (received, total) {
          if (mounted && total > 0) {
            setState(() {
              _downloadProgress[fileName] = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadingStatus[fileName] = false;
        });

        if (response != null && response.statusCode == 200) {
          _downloadProgress[fileName] = 1.0;
          _showSuccessSnackBar('File downloaded using SimpleApiRequest!');
        } else {
          setState(() {
            _downloadErrors[fileName] = 'Download failed with status: ${response?.statusCode}';
          });
          _showErrorSnackBar('Download failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingStatus[fileName] = false;
          _downloadErrors[fileName] = e.toString();
        });
        _showErrorSnackBar('Download error: $e');
      }
    }
  }

  /// Generic download method using action-based approach
  Future<void> _downloadWithAction({
    required String fileName,
    required Future<Either<ActionRequestError, String>?> Function() downloadFunction,
    required String title,
  }) async {
    setState(() {
      _downloadingStatus[fileName] = true;
      _downloadErrors.remove(fileName);
    });

    try {
      final result = await downloadFunction();
      
      if (mounted) {
        setState(() {
          _downloadingStatus[fileName] = false;
        });

        result?.fold(
          (error) {
            setState(() {
              _downloadErrors[fileName] = error.message ?? 'Download failed';
            });
            _showErrorSnackBar('Failed to download $title: ${error.message}');
          },
          (filePath) {
            _showSuccessSnackBar('$title downloaded successfully!');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadingStatus[fileName] = false;
          _downloadErrors[fileName] = e.toString();
        });
        _showErrorSnackBar('Download error: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Downloads Demo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'File Download Examples',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This screen demonstrates different approaches to downloading files using the API Request package:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Action-based downloads with FileDownloadAction\n'
                        '• Direct downloads with SimpleApiRequest\n'
                        '• Progress tracking and cancellation\n'
                        '• Error handling and file management',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            DownloadProgressCard(
              title: 'Sample PDF Document',
              fileName: 'sample_document.pdf',
              onDownload: _downloadSamplePdf,
              isDownloading: _downloadingStatus['sample_document.pdf'] ?? false,
              errorMessage: _downloadErrors['sample_document.pdf'],
            ),
            
            DownloadProgressCard(
              title: 'Sample Image (Action-based)',
              fileName: 'sample_image.jpg',
              onDownload: _downloadSampleImage,
              isDownloading: _downloadingStatus['sample_image.jpg'] ?? false,
              errorMessage: _downloadErrors['sample_image.jpg'],
            ),
            
            DownloadProgressCard(
              title: 'Large File with Progress',
              fileName: 'large_sample.jpg',
              onDownload: _downloadLargeFileWithProgress,
              isDownloading: _downloadingStatus['large_sample.jpg'] ?? false,
              progress: _downloadProgress['large_sample.jpg'],
              errorMessage: _downloadErrors['large_sample.jpg'],
            ),
            
            DownloadProgressCard(
              title: 'Direct Download (SimpleApiRequest)',
              fileName: 'direct_download.jpg',
              onDownload: _downloadWithSimpleApiRequest,
              isDownloading: _downloadingStatus['direct_download.jpg'] ?? false,
              progress: _downloadProgress['direct_download.jpg'],
              errorMessage: _downloadErrors['direct_download.jpg'],
            ),

            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code Examples',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Action-based Download:\n'
                        '```dart\n'
                        'final action = DownloadFileAction(savePath);\n'
                        'action.onProgress((received, total) => {\n'
                        '  // Handle progress updates\n'
                        '});\n'
                        'final result = await action.execute();\n'
                        '```\n\n'
                        'Direct Download:\n'
                        '```dart\n'
                        'final client = SimpleApiRequest.init();\n'
                        'final response = await client.download(\n'
                        '  url, savePath,\n'
                        '  onReceiveProgress: (received, total) => {\n'
                        '    // Handle progress\n'
                        '  },\n'
                        ');\n'
                        '```',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
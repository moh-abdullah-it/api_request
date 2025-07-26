import 'dart:io';

import 'package:flutter/material.dart';
import '../services/download_service.dart';

/// Widget to display download progress and manage downloaded files
class DownloadProgressCard extends StatefulWidget {
  final String title;
  final String fileName;
  final VoidCallback onDownload;
  final bool isDownloading;
  final double? progress;
  final String? errorMessage;

  const DownloadProgressCard({
    Key? key,
    required this.title,
    required this.fileName,
    required this.onDownload,
    this.isDownloading = false,
    this.progress,
    this.errorMessage,
  }) : super(key: key);

  @override
  State<DownloadProgressCard> createState() => _DownloadProgressCardState();
}

class _DownloadProgressCardState extends State<DownloadProgressCard> {
  bool _fileExists = false;

  @override
  void initState() {
    super.initState();
    _checkFileExists();
  }

  @override
  void didUpdateWidget(DownloadProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName) {
      _checkFileExists();
    }
  }

  Future<void> _checkFileExists() async {
    final exists = await DownloadService.fileExists(widget.fileName);
    if (mounted) {
      setState(() {
        _fileExists = exists;
      });
    }
  }

  Future<void> _openFile() async {
    try {
      final filePath = await DownloadService.getFilePath(widget.fileName);
      final file = File(filePath);
      
      if (await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to: $filePath'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteFile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${widget.fileName}"?'),
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
      final deleted = await DownloadService.deleteFile(widget.fileName);
      if (deleted && mounted) {
        setState(() {
          _fileExists = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusIcon(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'File: ${widget.fileName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (widget.isDownloading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_fileExists) {
      return Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 24,
      );
    } else if (widget.errorMessage != null) {
      return Icon(
        Icons.error,
        color: Colors.red,
        size: 24,
      );
    } else {
      return Icon(
        Icons.download,
        color: Colors.blue,
        size: 24,
      );
    }
  }

  Widget _buildContent() {
    if (widget.errorMessage != null) {
      return _buildErrorContent();
    } else if (widget.isDownloading) {
      return _buildDownloadingContent();
    } else if (_fileExists) {
      return _buildExistingFileContent();
    } else {
      return _buildDownloadButton();
    }
  }

  Widget _buildErrorContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.errorMessage!,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildDownloadButton(),
      ],
    );
  }

  Widget _buildDownloadingContent() {
    return Column(
      children: [
        if (widget.progress != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress: ${(widget.progress! * 100).toStringAsFixed(1)}%'),
              Text('${(widget.progress! * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: widget.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ] else ...[
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('Downloading...'),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExistingFileContent() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _openFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Show File'),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _deleteFile,
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.isDownloading ? null : widget.onDownload,
        icon: const Icon(Icons.download),
        label: const Text('Download'),
      ),
    );
  }
}
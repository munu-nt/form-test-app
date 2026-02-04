import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
class MultiFileUploadWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const MultiFileUploadWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<MultiFileUploadWidget> createState() => _MultiFileUploadWidgetState();
}
class _MultiFileUploadWidgetState extends State<MultiFileUploadWidget> {
  final List<MediaFile> _files = [];
  final _uuid = const Uuid();
  final int _maxFiles = 10;
  Future<void> _pickFiles() async {
    if (_files.length >= _maxFiles) {
      _showError('Maximum $_maxFiles files allowed');
      return;
    }
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (_files.length >= _maxFiles) break;
          final mediaFile = MediaFile(
            id: _uuid.v4(),
            name: file.name,
            path: file.path ?? '',
            mimeType: file.extension,
            sizeBytes: file.size,
          );
          setState(() {
            _files.add(mediaFile);
          });
          _simulateUpload(mediaFile);
        }
      }
    } catch (e) {
      _showError('Failed to pick files: $e');
    }
  }
  Future<void> _simulateUpload(MediaFile file) async {
    final index = _files.indexWhere((f) => f.id == file.id);
    if (index == -1) return;
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      final currentIndex = _files.indexWhere((f) => f.id == file.id);
      if (currentIndex == -1) return;  
      setState(() {
        _files[currentIndex] = file.copyWith(
          uploadProgress: i / 100,
          isUploading: i < 100,
          isUploaded: i == 100,
        );
      });
    }
    _notifyValue();
  }
  void _notifyValue() {
    final uploadedFiles = _files
        .where((f) => f.isUploaded)
        .map((f) => {
              'name': f.name,
              'path': f.path,
              'size': f.sizeBytes,
              'mimeType': f.mimeType,
            })
        .toList();
    widget.onValueChanged(widget.field.fieldId, uploadedFiles);
  }
  void _removeFile(String id) {
    setState(() {
      _files.removeWhere((f) => f.id == id);
    });
    _notifyValue();
  }
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_open, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Multiple Files', style: theme.textTheme.titleMedium),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_files.length}/$_maxFiles',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_files.length < _maxFiles)
              _buildAddButton(theme),
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._files.map((file) => _buildFileItem(file, theme)),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildAddButton(ThemeData theme) {
    return InkWell(
      onTap: _pickFiles,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Add Files',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFileItem(MediaFile file, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getFileIcon(file.mimeType),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      file.formattedSize,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (file.isUploading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: file.uploadProgress,
                    strokeWidth: 2,
                  ),
                )
              else if (file.isUploaded)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: theme.colorScheme.error),
                onPressed: () => _removeFile(file.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (file.isUploading) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: file.uploadProgress,
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }
}
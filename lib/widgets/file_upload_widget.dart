import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
class FileUploadWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const FileUploadWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}
class _FileUploadWidgetState extends State<FileUploadWidget> {
  MediaFile? _selectedFile;
  final _uuid = const Uuid();
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final mediaFile = MediaFile(
          id: _uuid.v4(),
          name: file.name,
          path: file.path ?? '',
          mimeType: file.extension,
          sizeBytes: file.size,
        );
        setState(() {
          _selectedFile = mediaFile;
        });
        _simulateUpload(mediaFile);
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }
  Future<void> _simulateUpload(MediaFile file) async {
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        _selectedFile = file.copyWith(
          uploadProgress: i / 100,
          isUploading: i < 100,
          isUploaded: i == 100,
        );
      });
    }
    _notifyValue();
  }
  void _notifyValue() {
    if (_selectedFile != null && _selectedFile!.isUploaded) {
      widget.onValueChanged(widget.field.fieldId, {
        'name': _selectedFile!.name,
        'path': _selectedFile!.path,
        'size': _selectedFile!.sizeBytes,
        'mimeType': _selectedFile!.mimeType,
      });
    }
  }
  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
    widget.onValueChanged(widget.field.fieldId, null);
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
                Icon(Icons.attach_file, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('File Upload', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedFile == null)
              _buildUploadArea(theme)
            else
              _buildFilePreview(theme),
          ],
        ),
      ),
    );
  }
  Widget _buildUploadArea(ThemeData theme) {
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to select a file',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Supports all file types',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildFilePreview(ThemeData theme) {
    final file = _selectedFile!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(file.mimeType),
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file.formattedSize,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (file.isUploading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: file.uploadProgress,
                    strokeWidth: 2,
                  ),
                )
              else if (file.isUploaded)
                Icon(Icons.check_circle, color: Colors.green)
              else if (file.errorMessage != null)
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.colorScheme.error),
                  onPressed: () => _simulateUpload(file),
                ),
              if (!file.isUploading)
                IconButton(
                  icon: Icon(Icons.close, color: theme.colorScheme.error),
                  onPressed: _removeFile,
                ),
            ],
          ),
          if (file.isUploading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: file.uploadProgress,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(file.uploadProgress * 100).toInt()}% uploaded',
              style: theme.textTheme.bodySmall,
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
      case 'avi':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models.dart';
class VideoPickerWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const VideoPickerWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<VideoPickerWidget> createState() => _VideoPickerWidgetState();
}
class _VideoPickerWidgetState extends State<VideoPickerWidget> {
  XFile? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  Duration? _duration;
  int? _sizeBytes;
  final ImagePicker _picker = ImagePicker();
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
  Future<void> _pickVideo(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        final file = File(video.path);
        final size = await file.length();
        if (size > 100 * 1024 * 1024) {
          _showError('Video too large. Maximum size is 100MB.');
          setState(() {
            _isLoading = false;
          });
          return;
        }
        _videoController?.dispose();
        _videoController = VideoPlayerController.file(file);
        await _videoController!.initialize();
        setState(() {
          _selectedVideo = video;
          _duration = _videoController!.value.duration;
          _sizeBytes = size;
        });
        _notifyValue();
      }
    } catch (e) {
      _showError('Failed to pick video: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _notifyValue() {
    if (_selectedVideo != null) {
      widget.onValueChanged(widget.field.fieldId, {
        'name': _selectedVideo!.name,
        'path': _selectedVideo!.path,
        'size': _sizeBytes,
        'duration': _duration?.inSeconds,
      });
    }
  }
  void _removeVideo() {
    _videoController?.dispose();
    _videoController = null;
    setState(() {
      _selectedVideo = null;
      _duration = null;
      _sizeBytes = null;
    });
    widget.onValueChanged(widget.field.fieldId, null);
  }
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  void _showPickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
                Icon(Icons.videocam, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Video', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing video...'),
                    ],
                  ),
                ),
              )
            else if (_selectedVideo == null)
              _buildPickerArea(theme)
            else
              _buildVideoPreview(theme),
          ],
        ),
      ),
    );
  }
  Widget _buildPickerArea(ThemeData theme) {
    return InkWell(
      onTap: _showPickerDialog,
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
              Icons.video_call,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to add a video',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Maximum 5 minutes, 100MB',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  avatar: const Icon(Icons.videocam, size: 16),
                  label: const Text('Record'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.video_library, size: 16),
                  label: const Text('Gallery'),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildVideoPreview(ThemeData theme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _videoController?.value.aspectRatio ?? 16 / 9,
                child: _videoController != null
                    ? VideoPlayer(_videoController!)
                    : Container(
                        color: Colors.black,
                        child: const Icon(Icons.videocam, color: Colors.white54, size: 48),
                      ),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(32),
              ),
              child: IconButton(
                icon: Icon(
                  _videoController?.value.isPlaying == true 
                      ? Icons.pause 
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  if (_videoController?.value.isPlaying == true) {
                    _videoController?.pause();
                  } else {
                    _videoController?.play();
                  }
                  setState(() {});
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _removeVideo,
                  tooltip: 'Remove video',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedVideo!.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          _duration != null ? _formatDuration(_duration!) : '--:--',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.storage, size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          _sizeBytes != null ? _formatSize(_sizeBytes!) : '--',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showPickerDialog,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Change'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
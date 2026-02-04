import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
class ImagePickerWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const ImagePickerWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}
class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  XFile? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        _notifyValue();
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _notifyValue() async {
    if (_selectedImage != null) {
      final file = File(_selectedImage!.path);
      final size = await file.length();
      widget.onValueChanged(widget.field.fieldId, {
        'name': _selectedImage!.name,
        'path': _selectedImage!.path,
        'size': size,
      });
    }
  }
  void _removeImage() {
    setState(() {
      _selectedImage = null;
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
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
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
                Icon(Icons.image, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Image', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_selectedImage == null)
              _buildPickerArea(theme)
            else
              _buildImagePreview(theme),
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
              Icons.add_a_photo,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to add an image',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  avatar: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Camera'),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.photo_library, size: 16),
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
  Widget _buildImagePreview(ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_selectedImage!.path),
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _showPickerDialog,
                  tooltip: 'Change image',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _removeImage,
                  tooltip: 'Remove image',
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(
              _selectedImage!.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models.dart';
class StaticImageView extends StatefulWidget {
  final FieldModel field;
  const StaticImageView({
    super.key,
    required this.field,
  });
  @override
  State<StaticImageView> createState() => _StaticImageViewState();
}
class _StaticImageViewState extends State<StaticImageView> {
  bool _isLoading = true;
  bool _hasError = false;
  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.field.fieldValue ?? '';
    if (imageUrl.isEmpty) {
      return _buildCompactPlaceholder();
    }
    return GestureDetector(
      onTap: () => _showFullScreen(context, imageUrl),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImageContent(imageUrl),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.zoom_in, color: Colors.white.withValues(alpha: 0.8), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to zoom',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading) _buildLoadingOverlay(),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildImageContent(String imageUrl) {
    if (imageUrl.startsWith('data:image/')) {
      return _buildBase64(imageUrl);
    } else if (imageUrl.startsWith('assets/')) {
      return _buildAsset(imageUrl);
    } else {
      return _buildNetwork(imageUrl);
    }
  }
  Widget _buildNetwork(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isLoading = false);
          });
          return child;
        }
        return const SizedBox.shrink();
      },
      errorBuilder: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() { _hasError = true; _isLoading = false; });
        });
        return _buildErrorContent();
      },
    );
  }
  Widget _buildAsset(String path) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildErrorContent(),
    );
  }
  Widget _buildBase64(String data) {
    try {
      final bytes = base64Decode(data.split(',').last);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return _buildErrorContent();
    }
  }
  Widget _buildLoadingOverlay() {
    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
  Widget _buildErrorContent() {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 32, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 4),
          Text('Failed to load', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }
  Widget _buildCompactPlaceholder() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 28, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 4),
            Text('No image', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }
  void _showFullScreen(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenViewer(
          imageUrl: imageUrl,
          title: widget.field.fieldName,
          fieldId: widget.field.fieldId,
        ),
      ),
    );
  }
}
class _FullScreenViewer extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String fieldId;
  const _FullScreenViewer({
    required this.imageUrl,
    required this.title,
    required this.fieldId,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 14)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }
  Widget _buildImage() {
    if (imageUrl.startsWith('data:image/')) {
      try {
        final bytes = base64Decode(imageUrl.split(',').last);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {
        return _buildError();
      }
    } else if (imageUrl.startsWith('assets/')) {
      return Image.asset(imageUrl, fit: BoxFit.contain);
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildError(),
      );
    }
  }
  Widget _buildError() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image, size: 48, color: Colors.white54),
        SizedBox(height: 8),
        Text('Failed to load', style: TextStyle(color: Colors.white54)),
      ],
    );
  }
}
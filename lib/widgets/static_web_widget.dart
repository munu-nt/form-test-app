import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models.dart';

class StaticWebWidget extends StatefulWidget {
  final FieldModel field;
  const StaticWebWidget({super.key, required this.field});
  @override
  State<StaticWebWidget> createState() => _StaticWebWidgetState();
}

class _StaticWebWidgetState extends State<StaticWebWidget> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final content = widget.field.fieldValue ?? '';
    if (content.isEmpty || !_isUrl(content)) return;
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.disabled)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) => setState(() => _isLoading = true),
            onPageFinished: (_) => setState(() => _isLoading = false),
            onWebResourceError: (_) => setState(() {
              _hasError = true;
              _isLoading = false;
            }),
          ),
        )
        ..loadRequest(Uri.parse(content));
    } catch (_) {
      _hasError = true;
    }
  }

  bool _isUrl(String s) => s.startsWith('http://') || s.startsWith('https://');
  bool _isHtml(String s) => s.contains('<') && s.contains('>');
  @override
  Widget build(BuildContext context) {
    final content = widget.field.fieldValue ?? '';
    if (content.isEmpty) {
      return _buildCompactPlaceholder('No content');
    }
    if (_isUrl(content)) {
      return _buildWebView(content);
    }
    return _buildHtmlContent(content);
  }

  Widget _buildWebView(String url) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _shortenUrl(url),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => _openFullScreen(url),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _controller != null && !_hasError
                  ? Stack(
                      children: [
                        WebViewWidget(controller: _controller!),
                        if (_isLoading)
                          Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    )
                  : _buildCompactPlaceholder(
                      _hasError ? 'Failed to load' : 'Open to view',
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHtmlContent(String html) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.code,
                size: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'HTML Content',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HtmlWidget(html, textStyle: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildCompactPlaceholder(String message) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.web,
              size: 20,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host +
          (uri.path.isNotEmpty && uri.path != '/' ? uri.path : '');
    } catch (_) {
      return url;
    }
  }

  void _openFullScreen(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _FullScreenWebView(url: url, title: widget.field.fieldName),
      ),
    );
  }
}

class _FullScreenWebView extends StatefulWidget {
  final String url;
  final String title;
  const _FullScreenWebView({required this.url, required this.title});
  @override
  State<_FullScreenWebView> createState() => _FullScreenWebViewState();
}

class _FullScreenWebViewState extends State<_FullScreenWebView> {
  late WebViewController _controller;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

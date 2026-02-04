import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../models.dart';
class EConsentWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const EConsentWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<EConsentWidget> createState() => _EConsentWidgetState();
}
class _EConsentWidgetState extends State<EConsentWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isAccepted = false;
  String get _termsContent {
    final description = widget.field.fieldDescription ?? '';
    if (description.isNotEmpty) return description;
    return '''
      <p style="color: #666;">
        Please read and accept the terms and conditions to proceed.
      </p>
    ''';
  }
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialScrollState();
    });
  }
  void _checkInitialScrollState() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }
  void _onScroll() {
    if (_hasScrolledToBottom) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 50) {
      setState(() {
        _hasScrolledToBottom = true;
      });
    }
  }
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  void _onAcceptChanged(bool? value) {
    if (!_hasScrolledToBottom) return;
    setState(() {
      _isAccepted = value ?? false;
    });
    widget.onValueChanged(
      widget.field.fieldId,
      _isAccepted ? 'accepted' : null,
    );
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isAccepted 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: _isAccepted ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.gavel,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terms & Conditions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Please read and scroll to the bottom',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasScrolledToBottom)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Read',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: HtmlWidget(
                      _termsContent,
                      textStyle: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (!_hasScrolledToBottom)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.0),
                              theme.colorScheme.surfaceContainerHighest,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              Text(
                                'Scroll to continue',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _hasScrolledToBottom ? 1.0 : 0.5,
              child: CheckboxListTile(
                value: _isAccepted,
                onChanged: _hasScrolledToBottom ? _onAcceptChanged : null,
                title: RichText(
                  text: TextSpan(
                    text: 'I have read and agree to the terms and conditions',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _hasScrolledToBottom 
                          ? theme.colorScheme.onSurface 
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    children: widget.field.isMandate
                        ? [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ]
                        : null,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                activeColor: theme.colorScheme.primary,
              ),
            ),
            if (widget.field.isMandate && !_isAccepted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'You must accept the terms to proceed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
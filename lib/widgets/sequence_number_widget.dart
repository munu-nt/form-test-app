import 'dart:convert';
import 'package:flutter/material.dart';
import '../models.dart';
class SequenceNumberWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const SequenceNumberWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<SequenceNumberWidget> createState() => _SequenceNumberWidgetState();
}
class _SequenceNumberWidgetState extends State<SequenceNumberWidget> {
  late String _sequenceValue;
  SequenceNumberConfig? _config;
  @override
  void initState() {
    super.initState();
    _parseConfig();
    _generateSequence();
  }
  void _parseConfig() {
    if (widget.field.fieldValue != null && widget.field.fieldValue!.isNotEmpty) {
      try {
        final configJson = json.decode(widget.field.fieldValue!);
        _config = SequenceNumberConfig.fromJson(configJson);
      } catch (_) {
        _config = SequenceNumberConfig();
      }
    } else {
      _config = SequenceNumberConfig(
        startingNumber: 1,
        startingNumberLength: 4,
        prefix: 'SEQ-',
        suffix: '',
      );
    }
  }
  void _generateSequence() {
    _sequenceValue = _config?.generateSequence() ?? 'SEQ-0001';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onValueChanged(widget.field.fieldId, _sequenceValue);
    });
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hideFieldName = _config?.hideFieldName ?? false;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hideFieldName) ...[
              Row(
                children: [
                  Icon(
                    Icons.tag,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sequence Number',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.numbers,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(
                      _sequenceValue,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Copy to clipboard',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied: $_sequenceValue'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This number is auto-generated and cannot be modified.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
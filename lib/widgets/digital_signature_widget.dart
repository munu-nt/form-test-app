import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../models.dart';

class DigitalSignatureWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  final Map<String, dynamic>? formData;
  const DigitalSignatureWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
    this.formData,
  });
  @override
  State<DigitalSignatureWidget> createState() => _DigitalSignatureWidgetState();
}

class _DigitalSignatureWidgetState extends State<DigitalSignatureWidget> {
  late SignatureController _signatureController;
  bool _hasSignature = false;
  Uint8List? _signatureBytes;
  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    _signatureController.addListener(_onSignatureChanged);
    _restoreSavedSignature();
  }

  void _restoreSavedSignature() {
    final savedData = widget.formData?[widget.field.fieldId];
    if (savedData != null &&
        savedData is Map &&
        savedData['signature'] != null) {
      try {
        final bytes = base64Decode(savedData['signature']);
        setState(() {
          _signatureBytes = bytes;
          _hasSignature = true;
        });
      } catch (e) {
        debugPrint('Failed to restore signature: $e');
      }
    }
  }

  void _onSignatureChanged() {
    final hasPoints = _signatureController.isNotEmpty;
    if (hasPoints != _hasSignature) {
      setState(() {
        _hasSignature = hasPoints;
      });
    }
  }

  @override
  void dispose() {
    _signatureController.removeListener(_onSignatureChanged);
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      _showError('Please draw your signature first');
      return;
    }
    try {
      final bytes = await _signatureController.toPngBytes();
      if (bytes != null) {
        setState(() {
          _signatureBytes = bytes;
        });
        final base64Signature = base64Encode(bytes);
        widget.onValueChanged(widget.field.fieldId, {
          'signature': base64Signature,
          'timestamp': DateTime.now().toIso8601String(),
        });
        _showSuccess('Signature captured successfully');
      }
    } catch (e) {
      _showError('Failed to save signature: $e');
    }
  }

  void _clearSignature() {
    _signatureController.clear();
    setState(() {
      _signatureBytes = null;
      _hasSignature = false;
    });
    widget.onValueChanged(widget.field.fieldId, null);
  }

  void _undoLastStroke() {
    _signatureController.undo();
    if (_signatureController.isEmpty) {
      setState(() {
        _hasSignature = false;
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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
                Icon(Icons.draw, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Digital Signature', style: theme.textTheme.titleMedium),
                const Spacer(),
                if (_signatureBytes != null)
                  Chip(
                    avatar: const Icon(Icons.check, size: 16),
                    label: const Text('Captured'),
                    backgroundColor: Colors.green.withValues(alpha: 0.2),
                    side: BorderSide.none,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_signatureBytes != null)
              _buildSignaturePreview(theme)
            else
              _buildSignatureCanvas(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureCanvas(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Draw your signature in the area below',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasSignature
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.5),
              width: _hasSignature ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Signature(
              controller: _signatureController,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Tooltip(
              message: 'Undo last stroke',
              child: IconButton.filledTonal(
                onPressed: _hasSignature ? _undoLastStroke : null,
                icon: const Icon(Icons.undo, size: 20),
                style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Clear signature',
              child: IconButton.filledTonal(
                onPressed: _hasSignature ? _clearSignature : null,
                icon: const Icon(Icons.clear, size: 20),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  foregroundColor: theme.colorScheme.error,
                  backgroundColor: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: _hasSignature ? _saveSignature : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Confirm Signature'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignaturePreview(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: Column(
            children: [
              Image.memory(_signatureBytes!, height: 150, fit: BoxFit.contain),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Signature captured',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _clearSignature,
            icon: const Icon(Icons.refresh),
            label: const Text('Sign Again'),
          ),
        ),
      ],
    );
  }
}

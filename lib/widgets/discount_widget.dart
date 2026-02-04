import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
class DiscountWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const DiscountWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<DiscountWidget> createState() => _DiscountWidgetState();
}
class _DiscountWidgetState extends State<DiscountWidget> {
  late TextEditingController _controller;
  String? _errorText;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.fieldValue ?? '0');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyValueChange();
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  void _notifyValueChange() {
    final value = double.tryParse(_controller.text) ?? 0.0;
    widget.onValueChanged(widget.field.fieldId, value);
  }
  String? _validate(String? value) {
    if (value == null || value.isEmpty) {
      return null;  
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return 'Please enter a valid number';
    }
    if (parsed < 0) {
      return 'Discount cannot be negative';
    }
    return null;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Row(
              children: [
                Icon(
                  Icons.discount_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Enter Discount',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.attach_money),
                hintText: '0.00',
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              readOnly: widget.field.isReadOnly,
              validator: _validate,
              onChanged: (value) {
                setState(() {
                  _errorText = _validate(value);
                });
                if (_errorText == null) {
                  _notifyValueChange();
                }
              },
            ),
            if (widget.field.fieldValue != null && widget.field.fieldValue!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Default: ${widget.field.fieldValue}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
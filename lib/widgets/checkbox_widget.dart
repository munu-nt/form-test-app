import 'package:flutter/material.dart';
import '../models.dart';

class CheckBoxWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  final Map<String, dynamic>? formData;
  const CheckBoxWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
    this.formData,
  });
  @override
  State<CheckBoxWidget> createState() => _CheckBoxWidgetState();
}

class _CheckBoxWidgetState extends State<CheckBoxWidget> {
  final Set<String> _selectedValues = {};
  @override
  void initState() {
    super.initState();
    final savedValue = widget.formData?[widget.field.fieldId];
    if (savedValue != null && savedValue.toString().isNotEmpty) {
      _selectedValues.addAll(savedValue.toString().split(','));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.field.fieldOptions == null ||
        widget.field.fieldOptions!.isEmpty) {
      return const Text('No options available');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...widget.field.fieldOptions!.map((option) {
          final isSelected = _selectedValues.contains(option.value);
          final price = double.tryParse(option.paymentAmount ?? '0') ?? 0.0;
          return CheckboxListTile(
            title: Row(
              children: [
                Text(option.text),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    '₹${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            value: isSelected,
            onChanged: (bool? checked) {
              setState(() {
                if (checked == true) {
                  _selectedValues.add(option.value);
                } else {
                  _selectedValues.remove(option.value);
                }
                String combined = _selectedValues.join(',');
                widget.onValueChanged(widget.field.fieldId, combined);
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
        if (_selectedValues.isNotEmpty) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '₹${_calculateTotal().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  double _calculateTotal() {
    double total = 0.0;
    if (widget.field.fieldOptions == null) return 0.0;
    for (var option in widget.field.fieldOptions!) {
      if (_selectedValues.contains(option.value)) {
        total += double.tryParse(option.paymentAmount ?? '0') ?? 0.0;
      }
    }
    return total;
  }
}

import 'package:flutter/material.dart';
import '../models.dart';

class CardSelector extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  final Map<String, dynamic>? formData;
  const CardSelector({
    super.key,
    required this.field,
    required this.onValueChanged,
    this.formData,
  });
  @override
  State<CardSelector> createState() => _CardSelectorState();
}

class _CardSelectorState extends State<CardSelector> {
  String? _selectedValue;
  @override
  void initState() {
    super.initState();
    _selectedValue = widget.formData?[widget.field.fieldId]?.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.field.fieldOptions == null) return const SizedBox.shrink();
    return Column(
      children: widget.field.fieldOptions!.map((option) {
        final isSelected = _selectedValue == option.value;
        return Card(
          elevation: isSelected ? 4 : 1,
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            onTap: widget.field.isReadOnly
                ? null
                : () {
                    setState(() {
                      _selectedValue = option.value;
                    });
                    widget.onValueChanged(widget.field.fieldId, option.value);
                  },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.text,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                        ),
                        if (option.code != null)
                          Text(
                            option.code!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

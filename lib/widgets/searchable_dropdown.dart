import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models.dart';
class SearchableDropdown extends StatefulWidget {
  final FieldModel field;
  final String? initialValue;
  final Function(String) onValueChanged;
  const SearchableDropdown({
    super.key,
    required this.field,
    this.initialValue,
    required this.onValueChanged,
  });
  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}
class _SearchableDropdownState extends State<SearchableDropdown> {
  final TextEditingController _controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.field.fieldOptions != null) {
      final option = widget.field.fieldOptions!.firstWhere(
        (e) => e.value == widget.initialValue,
        orElse: () => FieldOptionModel(value: '', text: ''),
      );
      if (option.value.isNotEmpty) {
        _controller.text = option.text;
      }
    }
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (widget.field.fieldOptions == null || widget.field.fieldOptions!.isEmpty) {
      String hintText = 'No options available';
      switch (widget.field.fieldType) {
        case 'StateList':
          hintText = 'Please select a Country first';
          break;
        case 'CountyList':
          hintText = 'Please select a State first';
          break;
        case 'CityList':
          hintText = 'Please select a County first';
          break;
        case 'ProgramList':
          hintText = 'Please select a Department first';
          break;
      }
      return TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: widget.field.fieldName,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Theme.of(context).disabledColor),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        double dropdownWidth = 200.0;  
        if (constraints.maxWidth.isFinite && constraints.maxWidth > 50) {
          dropdownWidth = math.max(150.0, constraints.maxWidth);
        }
        return DropdownMenu<String>(
          controller: _controller,
          width: dropdownWidth,
          initialSelection: widget.initialValue,
          label: Text(widget.field.fieldName),
          dropdownMenuEntries: widget.field.fieldOptions!.map<DropdownMenuEntry<String>>((option) {
            return DropdownMenuEntry<String>(
              value: option.value,
              label: option.text,
            );
          }).toList(),
          onSelected: (String? value) {
            if (value != null) {
              widget.onValueChanged(value);
            }
          },
          inputDecorationTheme: InputDecorationTheme(
             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
             filled: true,
          ),
        );
      },
    );
  }
}
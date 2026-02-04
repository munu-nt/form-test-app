import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models.dart';

class SearchableDropdown extends StatefulWidget {
  final FieldModel field;
  final String? initialValue;
  final Function(String) onValueChanged;
  final String? errorText;
  const SearchableDropdown({
    super.key,
    required this.field,
    this.initialValue,
    required this.onValueChanged,
    this.errorText,
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
    if (widget.field.fieldOptions == null ||
        widget.field.fieldOptions!.isEmpty) {
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).disabledColor,
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        double dropdownWidth = 200.0;
        if (constraints.maxWidth.isFinite && constraints.maxWidth > 50) {
          dropdownWidth = math.max(150.0, constraints.maxWidth);
        }
        final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownMenu<String>(
              controller: _controller,
              width: dropdownWidth,
              initialSelection: widget.initialValue,
              label: Text(widget.field.fieldName),
              dropdownMenuEntries: widget.field.fieldOptions!
                  .map<DropdownMenuEntry<String>>((option) {
                    return DropdownMenuEntry<String>(
                      value: option.value,
                      label: option.text,
                    );
                  })
                  .toList(),
              onSelected: (String? value) {
                if (value != null) {
                  widget.onValueChanged(value);
                }
              },
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: hasError 
                      ? BorderSide(color: Theme.of(context).colorScheme.error, width: 2)
                      : const BorderSide(),
                ),
                enabledBorder: hasError
                    ? OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
                      )
                    : null,
                filled: true,
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

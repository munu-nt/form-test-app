import 'package:flutter/material.dart';
import '../models.dart';

class MultiWebUrlWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const MultiWebUrlWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<MultiWebUrlWidget> createState() => _MultiWebUrlWidgetState();
}

class _MultiWebUrlWidgetState extends State<MultiWebUrlWidget> {
  final List<TextEditingController> _controllers = [];
  @override
  void initState() {
    super.initState();
    _addUrlField();
  }

  void _addUrlField([String text = '']) {
    final ctrl = TextEditingController(text: text);
    ctrl.addListener(_updateValue);
    setState(() {
      _controllers.add(ctrl);
    });
  }

  void _removeUrlField(int index) {
    if (_controllers.length <= 1) {
      _controllers[0].clear();
      return;
    }
    _controllers[index].removeListener(_updateValue);
    _controllers[index].dispose();
    setState(() {
      _controllers.removeAt(index);
    });
    _updateValue();
  }

  void _updateValue() {
    final urls = _controllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    widget.onValueChanged(widget.field.fieldId, urls.join(','));
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.field.fieldName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...List.generate(_controllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _controllers[index],
                        decoration: InputDecoration(
                          labelText: 'URL ${index + 1}',
                          prefixIcon: const Icon(Icons.link),
                        ),
                      ),
                    ),
                    if (_controllers.length > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _removeUrlField(index),
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => _addUrlField(),
              icon: const Icon(Icons.add),
              label: const Text('Add URL'),
            ),
          ],
        ),
      ),
    );
  }
}

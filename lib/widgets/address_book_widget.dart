import 'package:flutter/material.dart';
import '../models.dart';

class AddressBookWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const AddressBookWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<AddressBookWidget> createState() => _AddressBookWidgetState();
}

class _AddressBookWidgetState extends State<AddressBookWidget> {
  final _addr1Ctrl = TextEditingController();
  final _addr2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  String? _selectedCountry;
  final List<String> _countries = ['USA', 'Canada', 'India', 'UK', 'Australia'];
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.field.fieldName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(controller: _addr1Ctrl, label: 'Address Line 1'),
            const SizedBox(height: 8),
            _buildTextField(controller: _addr2Ctrl, label: 'Address Line 2'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(controller: _cityCtrl, label: 'City'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: _stateCtrl,
                    label: 'State',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _zipCtrl,
                    label: 'Postal Code',
                    isNumber: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    initialValue: _selectedCountry,
                    items: _countries
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCountry = val;
                        _updateValue();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: (_) => _updateValue(),
    );
  }

  void _updateValue() {
    final addressData = {
      'AddressLine1': _addr1Ctrl.text,
      'AddressLine2': _addr2Ctrl.text,
      'City': _cityCtrl.text,
      'State': _stateCtrl.text,
      'PostalCode': _zipCtrl.text,
      'Country': _selectedCountry,
    };
    widget.onValueChanged(widget.field.fieldId, addressData);
  }
}

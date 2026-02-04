import 'package:flutter/material.dart';
import 'models.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'widgets/appointment_widget.dart';
import 'widgets/address_book_widget.dart';
import 'widgets/searchable_dropdown.dart';
import 'widgets/checkbox_widget.dart';
import 'widgets/card_selector.dart';
import 'widgets/star_rating.dart';
import 'widgets/grouped_fields_widget.dart';
import 'widgets/date_picker_widget.dart';
import 'widgets/gps_location_widget.dart';
import 'widgets/map_picker_widget.dart';
import 'widgets/file_upload_widget.dart';
import 'widgets/multi_file_upload_widget.dart';
import 'widgets/image_picker_widget.dart';
import 'widgets/video_picker_widget.dart';
import 'widgets/digital_signature_widget.dart';
import 'widgets/image_view_widget.dart';
import 'widgets/static_web_widget.dart';
import 'widgets/discount_widget.dart';
import 'widgets/payment_summary_widget.dart';
import 'widgets/sequence_number_widget.dart';
import 'widgets/econsent_widget.dart';
import 'widgets/formula_widget.dart';
import 'widgets/multi_web_url_widget.dart';
import 'widgets/complex_field_widget.dart';

class DynamicFormField extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  final Map<String, dynamic> formData;
  final int displayIndex;
  final List<FieldModel>? allFields;
  const DynamicFormField({
    super.key,
    required this.field,
    required this.onValueChanged,
    required this.formData,
    required this.displayIndex,
    this.allFields,
  });
  @override
  State<DynamicFormField> createState() => _DynamicFormFieldState();
}

class _DynamicFormFieldState extends State<DynamicFormField> {
  late TextEditingController _textController;
  String? _dropdownValue;
  String? _parentFieldId;
  String? _lastParentValue;

  @override
  void initState() {
    super.initState();
    final savedValue = widget.formData[widget.field.fieldId];
    _textController = TextEditingController(text: savedValue?.toString());
    _dropdownValue = savedValue?.toString();
    
    
    if (widget.field.isDependent) {
      _parentFieldId = _findParentFieldId();
      if (_parentFieldId != null) {
        _lastParentValue = widget.formData[_parentFieldId];
      }
    }

    if (_dropdownValue != null && widget.field.fieldOptions != null) {
      final validValues = widget.field.fieldOptions!
          .map((e) => e.value)
          .toSet();
      if (!validValues.contains(_dropdownValue)) {
        _dropdownValue = null;
      }
    }
  }

  @override
  void didUpdateWidget(covariant DynamicFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    
    if (_parentFieldId != null) {
      final currentParentValue = widget.formData[_parentFieldId];
      if (currentParentValue != _lastParentValue) {
        _lastParentValue = currentParentValue;
        _checkDependencyValidity();
      }
    } else if (widget.formData != oldWidget.formData) {
       
       
    }
  }

  void _checkDependencyValidity() {
    if (widget.field.fieldOptions == null) return;
    
    
    List<FieldOptionModel> currentOptions = _getFilteredOptions();
    
    
    if (_dropdownValue != null &&
        !currentOptions.any((op) => op.value == _dropdownValue)) {
      setState(() {
        _dropdownValue = null;
      });
      widget.onValueChanged(widget.field.fieldId, null);
    }
  }

  List<FieldOptionModel> _getFilteredOptions() {
    if (widget.field.fieldOptions == null) return [];
    String? parentFieldId = _findParentFieldId();
    if (parentFieldId != null) {
      String? parentValue = widget.formData[parentFieldId];
      if (parentValue == null || parentValue.isEmpty) {
        return [];
      }
      return widget.field.fieldOptions!
          .where((op) => op.parentCode == parentValue)
          .toList();
    }
    return widget.field.fieldOptions!;
  }

  String? _findParentFieldId() {
    if (!widget.field.isDependent) return null;
    if (widget.allFields == null) return null;
    final fieldType = widget.field.fieldType;
    const Map<String, String> dependencyHierarchy = {
      'StateList': 'CountryList',
      'CountyList': 'StateList',
      'CityList': 'CountyList',
      'ProgramList': 'DepartmentList',
    };
    String? parentType = dependencyHierarchy[fieldType];
    if (parentType == null) return null;
    for (var field in widget.allFields!) {
      if (field.fieldDependencyConfig != null) {
        for (var depConfig in field.fieldDependencyConfig!) {
          if (depConfig.dependencyType == fieldType) {
            return field.fieldId;
          }
        }
      }
      if (field.fieldType == parentType) {
        return field.fieldId;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String? _validateField(String? value) {
    if (widget.field.isMandate) {
      if (value == null || value.trim().isEmpty) {
        return '${widget.field.fieldName} is required';
      }
    }
    if ((widget.field.fieldType == 'Email' ||
            widget.field.fieldType == 'EmailID') &&
        value != null &&
        value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Invalid email address';
      }
    }
    if (widget.field.fieldType == 'PostalCode') {
      String? countryValue = widget.formData['2005'];
      if (countryValue == 'US' && value != null && value.isNotEmpty) {
        if (!RegExp(r'^\d{5}(?:[-\s]\d{4})?$').hasMatch(value)) {
          return 'Invalid US Postal Code';
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.field.hideField) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.field.fieldType != 'Label' &&
              widget.field.fieldType != 'Divider' &&
              widget.field.fieldType != 'HtmlViewer')
            _buildLabel(),
          const SizedBox(height: 8),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildLabel() {
    
    return Row(
      children: [
        /*
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$displayIdx',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        */
        Expanded(
          child: RichText(
            text: TextSpan(
              text: widget.field.fieldName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              children: widget.field.isMandate
                  ? [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ]
                  : [],
            ),
          ),
        ),
        /*
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'ID: ${widget.field.fieldId}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        */
      ],
    );
  }

  Widget _buildInput() {
    if (widget.field.fieldType == 'GroupedFields') {
      return GroupedFieldsWidget(
        key: Key(widget.field.fieldId),
        field: widget.field,
        formData: widget.formData,
        onValueChanged: widget.onValueChanged,
      );
    }
    if (widget.field.fieldOptions != null &&
        widget.field.fieldOptions!.isNotEmpty) {
      if (widget.field.fieldType == 'ProgramProfile') {
        return CardSelector(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
          formData: widget.formData,
        );
      }
      if (widget.field.fieldType == 'CheckBox') {
        return CheckBoxWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
          formData: widget.formData,
        );
      }
      if (widget.field.fieldType == 'RadioButton') {
        return _buildRadioButton();
      }
      if ([
        'AcademicSchool',
        'CitizenshipList',
        'AcademicLevel',
        'DepartmentList',
        'ProgramList',
        'CityList',
        'CountyList',
        'CountryList',
        'StateList',
        'WorkshopList',
        'AdmitTermList',
        'CampusList',
        'ExhibitorList',
        'PartnerList',
        'Semester',
        'Forum',
        'DropDown',
      ].contains(widget.field.fieldType)) {
        List<FieldOptionModel> filteredOptions = _getFilteredOptions();
        FieldModel filteredField = FieldModel(
          fieldId: widget.field.fieldId,
          fieldName: widget.field.fieldName,
          fieldType: widget.field.fieldType,
          fieldValue: _dropdownValue,
          isMandate: widget.field.isMandate,
          isReadOnly: widget.field.isReadOnly,
          hideField: widget.field.hideField,
          fieldOptions: filteredOptions,
          fieldMaxLength: widget.field.fieldMaxLength,
          sequence: widget.field.sequence,
          index: widget.field.index,
        );
        return SearchableDropdown(
          key: Key(widget.field.fieldId),
          field: filteredField,
          initialValue: _dropdownValue,
          onValueChanged: (val) {
            setState(() => _dropdownValue = val);
            widget.onValueChanged(widget.field.fieldId, val);
          },
        );
      }
      return _buildDropdown();
    }
    switch (widget.field.fieldType) {
      case 'Rating':
        return StarRating(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
          formData: widget.formData,
        );
      case 'Divider':
        return _buildDivider();
      case 'Label':
        return _buildStaticLabel();
      case 'LikeUnlike':
        return _buildLikeUnlike();
      case 'FileUpload':
        return FileUploadWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
        );
      case 'MultiFileUpload':
        return MultiFileUploadWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
        );
      case 'Image':
        if (widget.field.fieldId == '5778') {
          return StaticImageView(
            key: Key(widget.field.fieldId),
            field: widget.field,
          );
        }
        return ImagePickerWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
        );
      case 'Video':
        return VideoPickerWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
        );
      case 'DigiSign':
        return DigitalSignatureWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
          formData: widget.formData,
        );
      case 'Discount':
        return DiscountWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
          formData: widget.formData,
        );
      case 'PaymentSummary':
        return PaymentSummaryWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          formData: widget.formData,
          allFields: widget.allFields ?? [],
        );
      case 'Formula':
        return FormulaWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          formData: widget.formData,
          onValueChanged: widget.onValueChanged,
        );
      case 'MultiWebUrl':
        return MultiWebUrlWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
        );
      case 'EmergencyContact':
      case 'UserProfile':
      case 'ProgramContactProfile':
      case 'PhoneBook':
      case 'ProgramProfile':
        return ComplexFieldWidget(
          key: Key(widget.field.fieldId),
          parentField: widget.field,
          allFields: widget.allFields ?? [],
          formData: widget.formData,
          onValueChanged: widget.onValueChanged,
        );
      case 'SequenceNumber':
        return SequenceNumberWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
        );
      case 'eConsent':
        return EConsentWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
        );
      case 'GPSLocation':
        return GpsLocationWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
        );
      case 'GeographicMap':
        return MapPickerWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
        );
      case 'CheckBox':
        return CheckBoxWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
          formData: widget.formData,
        );
      case 'WebView':
      case 'web_view':
        return StaticWebWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
        );
      case 'HtmlViewer':
        return _buildHtmlViewer();
      case 'TextArea':
        return _buildTextField(isTextArea: true);
      case 'InputBox':
      case 'TextBox':
        return _buildTextField(key: Key(widget.field.fieldId));
      case 'Email':
      case 'EmailID':
        return _buildTextField(
          inputType: TextInputType.emailAddress,
          key: Key(widget.field.fieldId),
        );
      
      case 'WebUrl':
        return _buildTextField(
          inputType: TextInputType.url,
          key: Key(widget.field.fieldId),
        );
      case 'PostalCode':
        return _buildTextField(
          inputType: TextInputType.number,
          key: Key(widget.field.fieldId),
        );
      case 'Time':
        return _buildTimePicker();
      case 'ArrivalDate':
      case 'Calendar':
      case 'DateTime':
        return DatePickerWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          onValueChanged: widget.onValueChanged,
          formData: widget.formData,
        );
      case 'AddressBook':
        return AddressBookWidget(
          field: widget.field,
          onValueChanged: widget.onValueChanged,
        );
      case 'AppointmentCalendar':
        return AppointmentWidget(
          field: widget.field,
          onValueChanged: widget.onValueChanged,
        );
      case 'GroupedFields':
        return GroupedFieldsWidget(
          key: Key(widget.field.fieldId),
          field: widget.field,
          formData: widget.formData,
          onValueChanged: widget.onValueChanged,
        );
      default:
        return _buildTextField();
    }
  }

  Widget _buildStaticLabel() {
    return Text(
      widget.field.fieldName,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
    );
  }

  Widget _buildHtmlViewer() {
    String htmlContent = widget.field.fieldName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: HtmlWidget(
        htmlContent,
        textStyle: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(thickness: 1.5);
  }

  Widget _buildLikeUnlike() {
    bool? isLiked;
    if (_textController.text == 'Like') isLiked = true;
    if (_textController.text == 'Unlike') isLiked = false;
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.thumb_up,
            color: isLiked == true
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          onPressed: widget.field.isReadOnly
              ? null
              : () {
                  setState(() {
                    _textController.text = 'Like';
                  });
                  widget.onValueChanged(widget.field.fieldId, 'Like');
                },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.thumb_down,
            color: isLiked == false
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          onPressed: widget.field.isReadOnly
              ? null
              : () {
                  setState(() {
                    _textController.text = 'Unlike';
                  });
                  widget.onValueChanged(widget.field.fieldId, 'Unlike');
                },
        ),
      ],
    );
  }

  Widget _buildRadioButton() {
    return Column(
      children: widget.field.fieldOptions!.map((option) {
        
        return RadioListTile<String>(
          title: Text(option.text),
          value: option.value,
          
          groupValue: _dropdownValue,
          
          onChanged: widget.field.isReadOnly
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _dropdownValue = value;
                    });
                    widget.onValueChanged(widget.field.fieldId, value);
                  }
                },
        );
      }).toList(),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      initialValue: _dropdownValue,
      isExpanded: true,
      hint: const Text('Select an option'),
      items: widget.field.fieldOptions!.map((option) {
        return DropdownMenuItem<String>(
          value: option.value,
          child: Text(option.text),
        );
      }).toList(),
      validator: _validateField,
      onChanged: widget.field.isReadOnly
          ? null
          : (value) {
              if (value != null) {
                setState(() {
                  _dropdownValue = value;
                });
                widget.onValueChanged(widget.field.fieldId, value);
              }
            },
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: widget.field.isReadOnly
          ? null
          : () async {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (pickedTime != null && mounted) {
                String formattedTime = pickedTime.format(context);
                setState(() {
                  _textController.text = formattedTime;
                });
                widget.onValueChanged(widget.field.fieldId, formattedTime);
              }
            },
      child: AbsorbPointer(
        child: TextFormField(
          controller: _textController,
          readOnly: true,
          validator: _validateField,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            suffixIcon: const Icon(Icons.access_time),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    bool isTextArea = false,
    TextInputType? inputType,
    Key? key,
  }) {
    return TextFormField(
      key: key,
      controller: _textController,
      readOnly: widget.field.isReadOnly,
      validator: _validateField,
      keyboardType: inputType,
      maxLines: isTextArea || widget.field.fieldType == 'AddressBook' ? 3 : 1,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      onChanged: (value) {
        widget.onValueChanged(widget.field.fieldId, value);
      },
    );
  }
}

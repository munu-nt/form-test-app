import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:test_1/database_helper.dart';
import 'package:test_1/models.dart';

class FormProvider extends ChangeNotifier {
  FormModel? _formModel;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, dynamic> _formData = {};
  bool _isDataLoaded = false;

  FormModel? get formModel => _formModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get formData => _formData;

  List<FieldModel> get visibleFields {
    if (_formModel == null) return [];
    final fields = _formModel!.fields;
    final complexTypes = {
      'AddressBook',
      'EmergencyContact',
      'PhoneBook',
      'ProgramContactProfile',
      'ProgramProfile',
      'UserProfile',
    };
    final complexIds = fields
        .where((f) => complexTypes.contains(f.fieldType))
        .map((f) => f.fieldId)
        .toSet();

    return fields.where((f) {
      if (complexIds.contains(f.fieldId)) {
        if (!complexTypes.contains(f.fieldType)) {
          return false;
        }
        return true;
      }
      if (f.isGroupedField) {
        if (f.fieldType == 'GroupedFields') return true;
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> loadFormData(AssetBundle bundle) async {
    if (_isDataLoaded) return;

    try {
      _isLoading = true;
      notifyListeners();

      final String response = await bundle.loadString('data/form-data.json');
      final data = json.decode(response);
      
      _formModel = FormModel.fromJson(data);
      if (_formModel != null) {
        String name = _formModel!.formName;
        name = name.replaceAll(RegExp(r'\d{1,2}-[A-Za-z]{3}-\d{4}\s*'), '');
        name = name.replaceAll(RegExp(r'\s*\[.*?\]\s*'), '');
        name = name.trim();
        if (name.isEmpty) name = 'Dynamic Form';
        
        _formModel = FormModel(
          status: _formModel!.status,
          errorType: _formModel!.errorType,
          formName: name,
          formCategory: _formModel!.formCategory,
          buttonType: _formModel!.buttonType,
          fields: _formModel!.fields,
        );
      }

      final savedData = await DatabaseHelper.loadFormData();
      if (savedData.isNotEmpty) {
        _formData.addAll(savedData);
      }
      
      _isDataLoaded = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load form data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateValue(String fieldId, dynamic value) {
    _formData[fieldId] = value;
    notifyListeners();
  }

  Future<void> saveFormData() async {
    await DatabaseHelper.saveFormData(_formData);
    notifyListeners();
  }

  Future<void> clearData() async {
    await DatabaseHelper.clearFormData();
    _formData.clear();
    notifyListeners();
  }

  List<String> validateForm() {
    final List<String> errors = [];
    final fieldsToCheck = visibleFields;

    for (final field in fieldsToCheck) {
      if (field.isReadOnly) continue;

      final value = _formData[field.fieldId];
      final exists = value != null && value.toString().trim().isNotEmpty;

      // 1. Mandatory Check
      if (field.isMandate && !exists) {
        errors.add('${field.fieldName} is required');
        continue;
      }

      // 2. Format Checks (Email)
      if (exists && (field.fieldType == 'Email' || field.fieldType == 'EmailID')) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value.toString())) {
          errors.add('${field.fieldName}: Invalid email address');
        }
      }

      // 3. Format Checks (Postal Code - US Only logic copied from widget)
      if (exists && field.fieldType == 'PostalCode') {
        // Assuming '2005' is the Country field ID as per widget logic
        String? countryValue = _formData['2005']; 
        if (countryValue == 'US') {
          if (!RegExp(r'^\d{5}(?:[-\s]\d{4})?$').hasMatch(value.toString())) {
             errors.add('${field.fieldName}: Invalid US Postal Code');
          }
        }
      }
    }
    return errors;
  }
}

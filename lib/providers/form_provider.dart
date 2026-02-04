import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:test_1/database_helper.dart';
import 'package:test_1/models.dart';

class FormProvider extends ChangeNotifier {
  FormModel? _formModel;
  bool _isLoading = true;
  bool _isClearing = false;
  String? _errorMessage;
  final Map<String, dynamic> _formData = {};
  bool _isDataLoaded = false;

  FormModel? get formModel => _formModel;
  bool get isLoading => _isLoading;
  bool get isClearing => _isClearing;
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

  final Map<String, String> _fieldErrors = {};
  Map<String, String> get fieldErrors => _fieldErrors;
  
  String? getFieldError(String fieldId) => _fieldErrors[fieldId];

  void clearErrors() {
    _fieldErrors.clear();
    notifyListeners();
  }

  void updateValue(String fieldId, dynamic value) {
    _formData[fieldId] = value;
    if (_fieldErrors.containsKey(fieldId)) {
      _fieldErrors.remove(fieldId);
    }
    notifyListeners();
  }

  Future<void> saveFormData() async {
    await DatabaseHelper.saveFormData(_formData);
    notifyListeners();
  }

  Future<void> clearData(AssetBundle bundle) async {
    _isLoading = true;
    _isClearing = true;
    notifyListeners();
    
    await DatabaseHelper.clearFormData();
    _formData.clear();
    _fieldErrors.clear();
    _isDataLoaded = false;
    
    await Future.delayed(const Duration(milliseconds: 300));
    
    await loadFormData(bundle);
    
    _isClearing = false;
    notifyListeners();
  }

  List<ValidationError> validateForm() {
    final List<ValidationError> errors = [];
    final fieldsToCheck = visibleFields;

    _fieldErrors.clear();

    for (final field in fieldsToCheck) {
      if (field.isReadOnly) continue;

      final value = _formData[field.fieldId];
      final exists = value != null && value.toString().trim().isNotEmpty;

      if (field.fieldType == 'GroupedFields') {
        if (value is List) {
          _validateGroupedFields(field, value, errors);
        } else if (field.isMandate) {
             final error = ValidationError(
                  fieldId: field.fieldId,
                  message: '${field.fieldName} is required',
                );
                errors.add(error);
                _fieldErrors[field.fieldId] = error.message;
        }
        continue;
      }
      
      if ([
        'EmergencyContact',
        'UserProfile',
        'ProgramContactProfile',
        'PhoneBook',
        'ProgramProfile'
      ].contains(field.fieldType)) {
        if (value is Map) {
          _validateComplexFields(field, value, errors);
        } else if (field.isMandate) {
             final error = ValidationError(
                  fieldId: field.fieldId,
                  message: '${field.fieldName} is required',
                );
                errors.add(error);
                _fieldErrors[field.fieldId] = error.message;
        }
        continue;
      }

      if (field.isMandate && !exists) {
        final error = ValidationError(
          fieldId: field.fieldId,
          message: '${field.fieldName} is required',
        );
        errors.add(error);
        _fieldErrors[field.fieldId] = error.message;
        continue;
      }

      if (exists && (field.fieldType == 'Email' || field.fieldType == 'EmailID')) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value.toString())) {
          final error = ValidationError(
            fieldId: field.fieldId,
            message: '${field.fieldName}: Invalid email address',
          );
          errors.add(error);
          _fieldErrors[field.fieldId] = error.message;
        }
      }

      if (exists && field.fieldType == 'PostalCode') {
        String? countryValue = _formData['2005']; 
        if (countryValue == 'US') {
          if (!RegExp(r'^\d{5}(?:[-\s]\d{4})?$').hasMatch(value.toString())) {
             final error = ValidationError(
               fieldId: field.fieldId,
               message: '${field.fieldName}: Invalid US Postal Code',
             );
             errors.add(error);
             _fieldErrors[field.fieldId] = error.message;
          }
        }
      }
    }
    
    if (errors.isNotEmpty) {
      notifyListeners();
    }
    
    return errors;
  }

  void _validateGroupedFields(FieldModel parentField, List<dynamic> groups, List<ValidationError> errors) {
    if (parentField.subFields == null) return;

    for (int i = 0; i < groups.length; i++) {
      final groupData = groups[i];
      if (groupData is! Map) continue;

      for (final subField in parentField.subFields!) {
         final uniqueId = '${parentField.fieldId}_${i}_${subField.fieldId}';
         _performSingleFieldValidation(subField, groupData[subField.fieldId], uniqueId, errors);
      }
    }
  }

  void _validateComplexFields(FieldModel parentField, dynamic data, List<ValidationError> errors) {
     if (_formModel == null) return;
     
     final children = _formModel!.fields.where(
        (f) => f.fieldId == parentField.fieldId && f.fieldType != parentField.fieldType
     ).toList();
     
     children.sort((a, b) {
        int seqA = int.tryParse(a.sequence ?? "0") ?? 0;
        int seqB = int.tryParse(b.sequence ?? "0") ?? 0;
        return seqA.compareTo(seqB);
     });
     
     if (data is! Map) return;

     final Set<String> generatedIds = {};

     for (var child in children) {
        String virtualId = "${parentField.fieldId}_${child.fieldName.replaceAll(RegExp(r'\s+'), '')}";
        if (generatedIds.contains(virtualId)) {
           virtualId = "${virtualId}_${child.index}";
        }
        generatedIds.add(virtualId);
        
        
        
        _performSingleFieldValidation(child, data[child.fieldName], virtualId, errors);
     }
  }

  void _performSingleFieldValidation(FieldModel field, dynamic value, String uniqueIdForError, List<ValidationError> errors) {
      final exists = value != null && value.toString().trim().isNotEmpty;
      
      if (field.isMandate && !exists) {
        final error = ValidationError(
          fieldId: uniqueIdForError,
          message: '${field.fieldName} is required',
        );
        errors.add(error);
        _fieldErrors[uniqueIdForError] = error.message;
        return;
      }

      if (exists && (field.fieldType == 'Email' || field.fieldType == 'EmailID')) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value.toString())) {
          final error = ValidationError(
            fieldId: uniqueIdForError,
            message: '${field.fieldName}: Invalid email address',
          );
          errors.add(error);
          _fieldErrors[uniqueIdForError] = error.message;
        }
      }

      if (exists && field.fieldType == 'PostalCode') {
        String? countryValue = _formData['2005']; 
        if (countryValue == 'US') {
          if (!RegExp(r'^\d{5}(?:[-\s]\d{4})?$').hasMatch(value.toString())) {
             final error = ValidationError(
               fieldId: uniqueIdForError,
               message: '${field.fieldName}: Invalid US Postal Code',
             );
             errors.add(error);
             _fieldErrors[uniqueIdForError] = error.message;
          }
        }
      }
  }

}

class ValidationError {
  final String fieldId;
  final String message;
  
  ValidationError({required this.fieldId, required this.message});
}

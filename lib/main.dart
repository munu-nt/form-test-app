import 'dart:convert';
import 'package:flutter/material.dart';
import 'models.dart';
import 'form_widgets.dart';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic Form Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
      themeMode: ThemeMode.light,
      home: const FormPage(),
    );
  }
}

class FormPage extends StatefulWidget {
  const FormPage({super.key});
  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  FormModel? _formModel;
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, dynamic> _formData = {};
  final _formKey = GlobalKey<FormState>();
  bool _isDataLoaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      _loadFormData();
      _isDataLoaded = true;
    }
  }

  Future<void> _loadFormData() async {
    try {
      final String response = await DefaultAssetBundle.of(
        context,
      ).loadString('data/form-data.json');
      final data = json.decode(response);
      setState(() {
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
      });
      final savedData = await DatabaseHelper.loadFormData();
      if (savedData.isNotEmpty && mounted) {
        _formData.addAll(savedData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📥 Previously saved data restored'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load form data: $e';
        _isLoading = false;
      });
    }
  }

  void _handleValueChanged(String fieldId, dynamic value) {
    setState(() {
      _formData[fieldId] = value;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await DatabaseHelper.saveFormData(_formData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('💾 Form data saved to database'),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Success'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Tooltip(
                  message: 'Data will persist when app reopens',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Form saved successfully!'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(const JsonEncoder.withIndent('  ').convert(_formData)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in the form')),
      );
    }
  }

  Future<void> _clearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
        title: const Text('Clear All Saved Data?'),
        content: const Text(
          'This will delete all saved form data from the database. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseHelper.clearFormData();
      if (!mounted) return;
      setState(() {
        _formData.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🗑️ All saved data cleared'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formModel?.formName ?? 'Loading...'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear saved data',
            onPressed: _clearDatabase,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _buildForm(),
      bottomNavigationBar: _formModel != null
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton(
                onPressed: _submitForm,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_formModel!.buttonType),
              ),
            )
          : null,
    );
  }

  Widget _buildForm() {
    if (_formModel == null) return const SizedBox.shrink();
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
    debugPrint('Total fields loaded: ${fields.length}');
    debugPrint('Complex Container IDs found: ${complexIds.length}');
    final filteredFields = fields.where((f) {
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
    debugPrint('Fields after filtering: ${filteredFields.length}');
    return Form(
      key: _formKey,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredFields.length,
        itemBuilder: (context, index) {
          return DynamicFormField(
            field: filteredFields[index],
            onValueChanged: _handleValueChanged,
            formData: _formData,
            displayIndex: index,
            allFields: fields,
          );
        },
      ),
    );
  }
}

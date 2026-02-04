import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_1/form_widgets.dart';
import 'package:test_1/providers/form_provider.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key});
  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<FormProvider>();
      await provider.loadFormData(DefaultAssetBundle.of(context));
      if (provider.formData.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📥 Previously saved data restored'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  Future<void> _submitForm() async {
    final provider = context.read<FormProvider>();
    
    // 1. Run provider-level validation (checks all fields, including off-screen ones)
    final errors = provider.validateForm();

    if (errors.isNotEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Validation Error'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please fix the following errors before submitting:'),
                const SizedBox(height: 12),
                ...errors.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      Expanded(child: Text(e)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return; 
    }

    // 2. Determine if we should proceed with FormState validation (only checks visible widgets)
    // Since provider validation passed, we know all data is good. 
    // We can skip _formKey.currentState!.validate() or keep it as a secondary UI check (e.g. focused fields).
    // It's safer to rely on provider validation for "completeness" and maybe run UI validation for "visual feedback" if needed,
    // but the error dialog is quite clear. Let's rely on provider logic primarily.

    await provider.saveFormData();
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
              Text(const JsonEncoder.withIndent('  ').convert(provider.formData)),
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
  }

  Future<void> _clearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 48,
        ),
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
      if (!mounted) return;
      await context.read<FormProvider>().clearData();
      if (!mounted) return;
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
    return Consumer<FormProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(provider.formModel?.formName ?? 'Loading...'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: 'Clear saved data',
                onPressed: _clearDatabase,
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.errorMessage != null
                  ? Center(child: Text(provider.errorMessage!))
                  : _buildForm(provider),
          bottomNavigationBar: provider.formModel != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FilledButton(
                    onPressed: _submitForm,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(provider.formModel!.buttonType),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildForm(FormProvider provider) {
    if (provider.formModel == null) return const SizedBox.shrink();
    
    final filteredFields = provider.visibleFields;
    
    return Form(
      key: _formKey,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredFields.length,
        itemBuilder: (context, index) {
          return DynamicFormField(
            field: filteredFields[index],
            onValueChanged: provider.updateValue,
            formData: provider.formData,
            displayIndex: index,
            allFields: provider.formModel!.fields,
          );
        },
      ),
    );
  }
}

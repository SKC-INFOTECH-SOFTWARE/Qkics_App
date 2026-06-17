import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/providers/company_provider.dart';
import 'package:dio/dio.dart';

import 'package:q_kics/models/company.dart';

class CreateCompanyPage extends StatefulWidget {
  final Company? company;
  const CreateCompanyPage({super.key, this.company});

  @override
  State<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends State<CreateCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _industryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  File? _logoFile;
  File? _coverFile;
  bool _isLoading = false;

  bool get isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.company!.name;
      _industryController.text = widget.company!.industry;
      _descriptionController.text = widget.company!.description;
      _locationController.text = widget.company!.location;
      _websiteController.text = widget.company!.website;
    }
  }

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoFile = File(pickedFile.path);
        } else {
          _coverFile = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'industry': _industryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
      };

      final provider = context.read<CompanyProvider>();

      if (_logoFile != null) {
        data['logo'] = await MultipartFile.fromFile(_logoFile!.path);
      }
      if (_coverFile != null) {
        data['cover_image'] = await MultipartFile.fromFile(_coverFile!.path);
      }

      Company? companyResult;
      
      try {
        if (isEditing) {
          companyResult = await provider.updateCompany(widget.company!.id, data);
        } else {
          companyResult = await provider.createCompany(data);
        }

        if (mounted) {
          setState(() => _isLoading = false);
          if (companyResult != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isEditing ? 'Company Updated!' : 'Company Created Successfully!')),
            );
            Navigator.pop(context, companyResult);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isEditing ? 'Failed to update company' : 'Failed to create company')),
            );
          }
        }
      } on DioException catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          
          String errorMsg = "API Error";
          if (e.response?.data != null) {
            // Extract messages from a standard map if it exists
            final responseData = e.response!.data;
            if (responseData is Map) {
              errorMsg = responseData.values.map((v) => v.toString()).join(" | ");
            } else {
              errorMsg = responseData.toString();
            }
          } else {
            errorMsg = e.message ?? "Unknown error";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${isEditing ? "Update failed" : "Creation failed"}: $errorMsg',
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Company' : 'Create Company'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Image Picker
              GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    image: _coverFile != null
                        ? DecorationImage(
                            image: FileImage(_coverFile!),
                            fit: BoxFit.cover,
                          )
                        : (isEditing && widget.company!.coverImage != null
                            ? DecorationImage(
                                image: NetworkImage(widget.company!.coverImage!),
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: (_coverFile == null && !(isEditing && widget.company!.coverImage != null))
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 40, color: colorScheme.primary),
                            const SizedBox(height: 8),
                            Text("Add Cover Image", style: TextStyle(color: colorScheme.onSurfaceVariant)),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                onPressed: () => _pickImage(false),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Logo Picker (Centered overlapping if we wanted, but let's keep it simple below)
              Center(
                child: GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.surface, width: 4),
                          image: _logoFile != null
                              ? DecorationImage(image: FileImage(_logoFile!), fit: BoxFit.cover)
                              : (isEditing && widget.company!.logo != null
                                  ? DecorationImage(image: NetworkImage(widget.company!.logo!), fit: BoxFit.cover)
                                  : null),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                          ],
                        ),
                        child: (_logoFile == null && !(isEditing && widget.company!.logo != null))
                            ? Icon(Icons.business, size: 40, color: colorScheme.onSurfaceVariant)
                            : null,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                controller: _nameController,
                label: 'Company Name',
                icon: Icons.business,
                validator: (val) => val == null || val.isEmpty ? 'Please enter company name' : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _industryController,
                label: 'Industry',
                icon: Icons.category_outlined,
                validator: (val) => val == null || val.isEmpty ? 'Please enter industry' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on_outlined,
                validator: (val) => val == null || val.isEmpty ? 'Please enter location' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _websiteController,
                label: 'Website',
                icon: Icons.language,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description_outlined,
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? 'Please enter description' : null,
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: colorScheme.primary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEditing ? 'Update Company' : 'Create Company',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1 ? Icon(icon, color: theme.colorScheme.primary) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
    );
  }
}

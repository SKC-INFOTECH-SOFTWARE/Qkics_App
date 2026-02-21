import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/profile/ui/upgrade/expert/certification_section.dart';
import 'package:q_kics/profile/ui/upgrade/expert/education_section.dart';
import 'package:q_kics/profile/ui/upgrade/expert/experience_section.dart';
import 'package:q_kics/profile/ui/upgrade/expert/honor_section.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/providers/expert_profile_provider.dart';

class ExpertProfileForm extends StatefulWidget {
  const ExpertProfileForm({super.key});

  @override
  State<ExpertProfileForm> createState() => _ExpertProfileFormState();
}

class _ExpertProfileFormState extends State<ExpertProfileForm> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _headline = TextEditingController();
  final _primaryExpertise = TextEditingController();
  final _otherExpertise = TextEditingController();
  final _hourlyRate = TextEditingController();

  bool _isAvailable = true;
  bool _filledOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpertProfileProvider>().fetchExpertProfile();
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _headline.dispose();
    _primaryExpertise.dispose();
    _otherExpertise.dispose();
    _hourlyRate.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() => {
        "first_name": _firstName.text.trim(),
        "last_name": _lastName.text.trim(),
        "headline": _headline.text.trim(),
        "primary_expertise": _primaryExpertise.text.trim(),
        "other_expertise": _otherExpertise.text.trim(),
        "hourly_rate": int.tryParse(_hourlyRate.text) ?? 0,
        "is_available": _isAvailable,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expert Profile')),
      body: Consumer<ExpertProfileProvider>(
        builder: (context, provider, child) {
          // ✅ Show loader only until first fetch completes
          if (!provider.initialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return _buildForm(provider);
        },
      ),
    );
  }

  Widget _buildForm(ExpertProfileProvider provider) {
    final profile = provider.profile;
    final user = context.read<ApiProvider>().currentUser;

    if (!_filledOnce) {
      if (profile != null) {
        // 🔹 EDIT MODE (Expert profile exists)

        _firstName.text = profile.firstName.isNotEmpty
            ? profile.firstName
            : (user?.firstName ?? '');

        _lastName.text = profile.lastName.isNotEmpty
            ? profile.lastName
            : (user?.lastName ?? '');

        _headline.text = profile.headline;
        _primaryExpertise.text = profile.primaryExpertise;
        _otherExpertise.text = profile.otherExpertise ?? '';

        if (profile.hourlyRate != null && profile.hourlyRate! > 0) {
          _hourlyRate.text = profile.hourlyRate.toString();
        }

        _isAvailable = profile.isAvailable;
      } else if (user != null) {
        // 🔹 CREATE MODE (No expert profile yet)

        _firstName.text = user.firstName;
        _lastName.text = user.lastName;
      }

      _filledOnce = true;
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_firstName, 'First Name'),
          _field(_lastName, 'Last Name'),
          _field(_headline, 'Headline'),
          _field(_primaryExpertise, 'Primary Expertise'),
          _field(_otherExpertise, 'Other Expertise'),
          _field(
            _hourlyRate,
            'Hourly Rate',
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            title: const Text('Available for consultation'),
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: provider.actionLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;

                    await provider.createOrUpdateProfile(_payload());

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile saved successfully'),
                      ),
                    );

                    Navigator.pop(context);
                  },
            child: provider.actionLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Profile'),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const Text(
            'Expert Portfolio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          const ExperienceSection(),
          const EducationSection(),
          const CertificationSection(),
          const HonorSection(),

          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: provider.actionLoading
                ? null
                : () async {
                    final note = await _reviewNoteDialog(context);
                    if (note == null || note.isEmpty) return;

                    await provider.submitForExpertReview(note: note);

                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Submit for Admin Review'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: (v) =>
            v == null || v.isEmpty ? 'This field is required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<String?> _reviewNoteDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit for Review'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Message to admin'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

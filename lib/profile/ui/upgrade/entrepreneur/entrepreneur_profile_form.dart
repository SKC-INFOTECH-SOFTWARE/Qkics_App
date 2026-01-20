import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/providers/entrepreneur_profile_provider.dart';

class EntrepreneurProfileForm extends StatefulWidget {
  const EntrepreneurProfileForm({super.key});

  @override
  State<EntrepreneurProfileForm> createState() =>
      _EntrepreneurProfileFormState();
}

class _EntrepreneurProfileFormState extends State<EntrepreneurProfileForm> {
  final _formKey = GlobalKey<FormState>();

  final _startupName = TextEditingController();
  final _oneLiner = TextEditingController();
  final _description = TextEditingController();
  final _website = TextEditingController();
  final _industry = TextEditingController();
  final _location = TextEditingController();

  bool _hydrated = false;

  @override
  void dispose() {
    _startupName.dispose();
    _oneLiner.dispose();
    _description.dispose();
    _website.dispose();
    _industry.dispose();
    _location.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    return {
      "startup_name": _startupName.text.trim(),
      "one_liner": _oneLiner.text.trim(),
      "description": _description.text.trim(),
      "website": _website.text.trim(),
      "industry": _industry.text.trim(),
      "location": _location.text.trim(),
    };
  }

  void _hydrateFields(EntrepreneurProfileProvider provider) {
    final p = provider.profile;
    if (p == null || _hydrated) return;

    _startupName.text = p.startupName;
    _oneLiner.text = p.oneLiner;
    _description.text = p.description ?? '';
    _website.text = p.website ?? '';
    _industry.text = p.industry;
    _location.text = p.location;

    _hydrated = true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EntrepreneurProfileProvider>(
      builder: (_, provider, __) {
        if (provider.loading && provider.profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ hydrate AFTER data arrives
        _hydrateFields(provider);

        return Scaffold(
          appBar: AppBar(title: const Text('Entrepreneur Profile')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _field(_startupName, 'Startup Name'),
                _field(_oneLiner, 'One Liner'),
                _field(_description, 'Description', maxLines: 3),
                _field(_website, 'Website', keyboardType: TextInputType.url),
                _field(_industry, 'Industry'),
                _field(_location, 'Location'),

                const SizedBox(height: 24),

                ElevatedButton(
  onPressed: () async {
    if (!_formKey.currentState!.validate()) return;

    final provider =
        context.read<EntrepreneurProfileProvider>();

    await provider.createOrUpdateProfile(_payload());

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved')),
    );

    Navigator.pop(context); // AboutTab updates instantly
  },
  child: const Text('Save Profile'),
),


                if (provider.hasDraft) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () async {
                      await provider.submitForEntrepreneurReview();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Submit for Admin Review'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

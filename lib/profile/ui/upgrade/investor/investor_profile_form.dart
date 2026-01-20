import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/providers/investor_profile_provider.dart';
import 'package:q_kics/profile/models/investor/investor_profile.dart';

class InvestorProfileForm extends StatefulWidget {
  const InvestorProfileForm({super.key});

  @override
  State<InvestorProfileForm> createState() => _InvestorProfileFormState();
}

class _InvestorProfileFormState extends State<InvestorProfileForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  TextEditingController? displayNameCtrl;
  TextEditingController? oneLinerCtrl;
  TextEditingController? thesisCtrl;
  TextEditingController? minCheckCtrl;
  TextEditingController? maxCheckCtrl;
  TextEditingController? locationCtrl;
  TextEditingController? websiteCtrl;
  TextEditingController? linkedinCtrl;
  TextEditingController? twitterCtrl;

  String investorType = 'angel';
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    /// 🔑 ENSURE PROFILE IS LOADED
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<InvestorProfileProvider>();

      if (provider.profile == null && !provider.isLoading) {
        await provider.fetchMyProfile();
      }
    });
  }

  void _initControllers(InvestorProfile profile) {
    displayNameCtrl =
        TextEditingController(text: profile.displayName);
    oneLinerCtrl =
        TextEditingController(text: profile.oneLiner);
    thesisCtrl =
        TextEditingController(text: profile.investmentThesis);
    minCheckCtrl =
        TextEditingController(text: profile.checkSizeMin.toString());
    maxCheckCtrl =
        TextEditingController(text: profile.checkSizeMax.toString());
    locationCtrl =
        TextEditingController(text: profile.location);
    websiteCtrl =
        TextEditingController(text: profile.websiteUrl ?? '');
    linkedinCtrl =
        TextEditingController(text: profile.linkedinUrl ?? '');
    twitterCtrl =
        TextEditingController(text: profile.twitterUrl ?? '');

    investorType = profile.investorType;
    _initialized = true;
  }

  @override
  void dispose() {
    displayNameCtrl?.dispose();
    oneLinerCtrl?.dispose();
    thesisCtrl?.dispose();
    minCheckCtrl?.dispose();
    maxCheckCtrl?.dispose();
    locationCtrl?.dispose();
    websiteCtrl?.dispose();
    linkedinCtrl?.dispose();
    twitterCtrl?.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await context.read<InvestorProfileProvider>().updateProfile({
        "display_name": displayNameCtrl!.text.trim(),
        "one_liner": oneLinerCtrl!.text.trim(),
        "investment_thesis": thesisCtrl!.text.trim(),
        "check_size_min": minCheckCtrl!.text.trim(),
        "check_size_max": maxCheckCtrl!.text.trim(),
        "location": locationCtrl!.text.trim(),
        "website_url": websiteCtrl!.text.trim().isEmpty
            ? null
            : websiteCtrl!.text.trim(),
        "linkedin_url": linkedinCtrl!.text.trim().isEmpty
            ? null
            : linkedinCtrl!.text.trim(),
        "twitter_url": twitterCtrl!.text.trim().isEmpty
            ? null
            : twitterCtrl!.text.trim(),
        "investor_type": investorType,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Investor profile updated")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InvestorProfileProvider>(
      builder: (_, provider, __) {
        // ⏳ LOADING
        if (provider.isLoading && !_initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🆕 FIRST TIME INVESTOR (no profile yet)
        if (provider.profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Create Investor Profile")),
            body: const Center(
              child: Text("Investor profile not found"),
            ),
          );
        }

        // ✅ INIT CONTROLLERS ONCE DATA IS READY
        if (!_initialized) {
          _initControllers(provider.profile!);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Edit Investor Profile"),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _field("Display Name", displayNameCtrl!),
                  _field("One-liner", oneLinerCtrl!),
                  _field(
                    "Investment Thesis",
                    thesisCtrl!,
                    maxLines: 4,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          "Min Check Size",
                          minCheckCtrl!,
                          keyboard: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          "Max Check Size",
                          maxCheckCtrl!,
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _field("Location", locationCtrl!),
                  _field("Website", websiteCtrl!),
                  _field("LinkedIn", linkedinCtrl!),
                  _field("Twitter", twitterCtrl!),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: investorType,
                    decoration: const InputDecoration(
                      labelText: "Investor Type",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'angel',
                          child: Text("Angel Investor")),
                      DropdownMenuItem(
                          value: 'vc', child: Text("VC Firm")),
                      DropdownMenuItem(
                          value: 'family_office',
                          child: Text("Family Office")),
                      DropdownMenuItem(
                          value: 'corporate',
                          child: Text("Corporate VC")),
                    ],
                    onChanged: (v) =>
                        setState(() => investorType = v!),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                            )
                          : const Text("Save Changes"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: (v) =>
            v == null || v.trim().isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

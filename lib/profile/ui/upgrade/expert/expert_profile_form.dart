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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Expert Profile'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<ExpertProfileProvider>(
        builder: (context, provider, child) {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_filledOnce) {
      if (profile != null) {
        _firstName.text = profile.firstName.isNotEmpty
            ? profile.firstName
            : (user?.firstName ?? '');
        _lastName.text = profile.lastName.isNotEmpty
            ? profile.lastName
            : (user?.lastName ?? '');
        _headline.text = profile.headline;
        _primaryExpertise.text = profile.primaryExpertise;
        _otherExpertise.text = profile.otherExpertise ?? '';
        if (profile.hourlyRate > 0) {
          _hourlyRate.text = profile.hourlyRate.toString();
        }
        _isAvailable = profile.isAvailable;
      } else if (user != null) {
        _firstName.text = user.firstName;
        _lastName.text = user.lastName;
      }
      _filledOnce = true;
    }

    final status = profile?.applicationStatus;
    final isPending = status == 'pending';
    final isApproved = status == 'approved';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ─── APPLICATION STATUS BANNER ───
          if (status != null && status != 'draft') ...[
            _statusBanner(theme, status, profile?.adminReviewNote),
            const SizedBox(height: 16),
          ],

          // ─── BASIC INFO CARD ───
          _sectionCard(
            theme,
            title: 'Basic Information',
            icon: Icons.person_outline_rounded,
            children: [
              Row(
                children: [
                  Expanded(child: _field(_firstName, 'First Name')),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_lastName, 'Last Name')),
                ],
              ),
              _field(_headline, 'Headline', hint: 'e.g. Senior Product Strategist'),
            ],
          ),

          const SizedBox(height: 16),

          // ─── EXPERTISE & RATE CARD ───
          _sectionCard(
            theme,
            title: 'Expertise & Rate',
            icon: Icons.workspace_premium_outlined,
            children: [
              _field(_primaryExpertise, 'Primary Expertise', hint: 'e.g. Product Management'),
              _field(
                _otherExpertise,
                'Other Expertise',
                hint: 'Optional',
                required: false,
              ),
              _field(
                _hourlyRate,
                'Hourly Rate (₹)',
                hint: 'e.g. 2000',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 4),
              _availabilityTile(theme),
            ],
          ),

          const SizedBox(height: 20),

          // ─── SAVE BUTTON ───
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: (provider.actionLoading || isPending || isApproved)
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      await provider.createOrUpdateProfile(_payload());
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Profile saved successfully'),
                            ],
                          ),
                          backgroundColor: Colors.green[700],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    },
              icon: provider.actionLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 20),
              label: Text(
                provider.actionLoading ? 'Saving...' : 'Save Profile',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ─── PORTFOLIO SECTION ───
          Row(
            children: [
              Icon(Icons.work_history_outlined, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Expert Portfolio',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Add your experiences, education and achievements to strengthen your profile.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          const ExperienceSection(),
          const EducationSection(),
          const CertificationSection(),
          const HonorSection(),

          const SizedBox(height: 28),

          // ─── SUBMIT FOR REVIEW ───
          if (!isPending && !isApproved) ...[
            _submitForReviewCard(theme, colorScheme, provider),
          ],
        ],
      ),
    );
  }

  Widget _statusBanner(ThemeData theme, String status, String? adminNote) {
    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    switch (status) {
      case 'pending':
        bgColor = Colors.amber.withValues(alpha: 0.08);
        borderColor = Colors.amber.withValues(alpha: 0.4);
        iconColor = Colors.amber[800]!;
        icon = Icons.hourglass_top_rounded;
        title = 'Under Admin Review';
        subtitle = 'Your application has been submitted and is being reviewed. We\'ll notify you once a decision is made.';
        break;
      case 'approved':
        bgColor = Colors.green.withValues(alpha: 0.08);
        borderColor = Colors.green.withValues(alpha: 0.4);
        iconColor = Colors.green[700]!;
        icon = Icons.verified_rounded;
        title = 'Application Approved';
        subtitle = 'Congratulations! Your expert profile has been approved.';
        break;
      case 'rejected':
        bgColor = Colors.red.withValues(alpha: 0.08);
        borderColor = Colors.red.withValues(alpha: 0.4);
        iconColor = Colors.red[700]!;
        icon = Icons.cancel_outlined;
        title = 'Application Rejected';
        subtitle = adminNote?.isNotEmpty == true
            ? 'Admin note: $adminNote'
            : 'Your application was not approved. Please update your profile and resubmit.';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: iconColor.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: required
            ? (v) => (v == null || v.isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          isDense: true,
        ),
      ),
    );
  }

  Widget _availabilityTile(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
      ),
      child: SwitchListTile(
        title: const Text(
          'Available for consultation',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _isAvailable ? 'Visible to clients for booking' : 'Hidden from booking',
          style: TextStyle(
            fontSize: 12,
            color: _isAvailable ? Colors.green[700] : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: _isAvailable,
        onChanged: (v) => setState(() => _isAvailable = v),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _submitForReviewCard(
    ThemeData theme,
    ColorScheme colorScheme,
    ExpertProfileProvider provider,
  ) {
    final hasSavedProfile = provider.profile != null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.06),
            colorScheme.secondary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to become an Expert?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Submit your profile for admin review. This usually takes 1–2 business days.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.tonalIcon(
              onPressed: (provider.actionLoading || !hasSavedProfile)
                  ? null
                  : () async {
                      final note = await _reviewNoteDialog(context);
                      if (note == null || note.isEmpty) return;

                      await provider.submitForExpertReview(note: note);

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.hourglass_top_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Submitted! Under admin review.'),
                            ],
                          ),
                          backgroundColor: Colors.amber[800],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );

                      Navigator.pop(context);
                    },
              icon: provider.actionLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.admin_panel_settings_outlined, size: 18),
              label: Text(
                provider.actionLoading
                    ? 'Submitting...'
                    : !hasSavedProfile
                        ? 'Save profile first'
                        : 'Submit for Admin Review',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (!hasSavedProfile) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Save your profile above before submitting.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<String?> _reviewNoteDialog(BuildContext context) async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined,
                color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('Submit for Review'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a short note to the admin (optional but recommended).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. I have 8 years of experience in fintech...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Submit'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

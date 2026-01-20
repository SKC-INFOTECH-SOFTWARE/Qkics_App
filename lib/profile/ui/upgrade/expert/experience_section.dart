import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/profile/ui/widgets/profile_form_fields.dart';
import 'package:q_kics/profile/utils/bottom_sheet_utils.dart';
import 'package:q_kics/providers/expert_profile_provider.dart';

/// ===============================================================
/// EMPLOYMENT TYPES (BACKEND SAFE)
/// ===============================================================
const employmentTypes = [
  {'value': 'full_time', 'label': 'Full-time'},
  {'value': 'part_time', 'label': 'Part-time'},
  {'value': 'internship', 'label': 'Internship'},
  {'value': 'contract', 'label': 'Contract'},
  {'value': 'freelance', 'label': 'Freelance'},
  {'value': 'research', 'label': 'Research'},
  {'value': 'other', 'label': 'Other'},
];

String employmentLabel(String? value) {
  final match = employmentTypes
      .firstWhere(
        (e) => e['value'] == value,
        orElse: () => const {'label': 'Other'},
      );
  return match['label']!;
}

class ExperienceSection extends StatefulWidget {
  final List<Map<String, dynamic>>? publicExperiences;
  final bool isPublicView;

  const ExperienceSection({
    super.key,
    this.publicExperiences,
    this.isPublicView = false,
  });

  @override
  State<ExperienceSection> createState() => _ExperienceSectionState();
}

class _ExperienceSectionState extends State<ExperienceSection> {
  bool expanded = true;
  bool _loaded = false;
  final Set<int> _openCards = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.isPublicView && !_loaded) {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ExpertProfileProvider>().fetchExpertProfile();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final list = widget.isPublicView
        ? List<Map<String, dynamic>>.from(
            widget.publicExperiences ?? const [],
          )
        : context.watch<ExpertProfileProvider>().experiences;

    list.sort(
      (a, b) => (b['start_date'] ?? '').compareTo(a['start_date'] ?? ''),
    );

    if (list.isEmpty && widget.isPublicView) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: theme.brightness == Brightness.dark ? 6 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _header(context),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: List.generate(
                  list.length,
                  (i) => _experienceCard(context, list[i], i),
                ),
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _header(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.work_outline,
            color: theme.colorScheme.primary),
      ),
      title: Text(
        'Experience',
        style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.isPublicView)
            IconButton(
              icon: Icon(Icons.add,
                  color: theme.colorScheme.primary),
              onPressed: () => _openSheet(
                context,
                context.read<ExpertProfileProvider>(),
              ),
            ),
          IconButton(
            icon: AnimatedRotation(
              turns: expanded ? 0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more),
            ),
            onPressed: () => setState(() => expanded = !expanded),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXPERIENCE CARD (SMOOTH)
  // ============================================================
  Widget _experienceCard(
    BuildContext context,
    Map<String, dynamic> e,
    int index,
  ) {
    final theme = Theme.of(context);
    final isOpen = _openCards.contains(index);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          isOpen
              ? _openCards.remove(index)
              : _openCards.add(index);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
      //  margin: const EdgeInsets.only(bottom: 12),
         padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= SUMMARY =================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _icon(theme),
                // const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['job_title'] ?? '',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e['company'] ?? '',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${e['start_date']} - ${e['end_date'] ?? 'Present'}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more),
                ),
                if (!widget.isPublicView)
                  _menu(context, e),
              ],
            ),

            // ================= DETAILS =================
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isOpen
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _details(theme, e),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAILS (INNER CLEAN CARD)
  // ============================================================
  Widget _details(ThemeData theme, Map<String, dynamic> e) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(
            theme,
            Icons.badge_outlined,
            'Employment',
            employmentLabel(e['employment_type']),
          ),
          if (e['location']?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _row(
              theme,
              Icons.location_on_outlined,
              'Location',
              e['location'],
            ),
          ],
          if (e['description']?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _row(
              theme,
              Icons.notes_outlined,
              'Description',
              e['description'],
              multiline: true,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // MENU
  // ============================================================
  Widget _menu(BuildContext context, Map<String, dynamic> e) {
    final provider = context.read<ExpertProfileProvider>();
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (v) {
        if (v == 'edit') {
          _openSheet(context, provider, experience: e);
        } else {
          provider.deleteExperience(e['id']);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Widget _icon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.work_outline,
          color: theme.colorScheme.primary),
    );
  }

  Widget _row(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    bool multiline = false,
  }) {
    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall,
              children: [
                TextSpan(
                  text: '$label: ',
                  style:
                      const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM SHEET
  // ============================================================
  void _openSheet(
    BuildContext context,
    ExpertProfileProvider provider, {
    Map<String, dynamic>? experience,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          ExperienceSheet(provider: provider, experience: experience),
    );
  }
}

/// ===============================================================
/// EXPERIENCE SHEET (LOGIC UNCHANGED)
/// ===============================================================
class ExperienceSheet extends StatefulWidget {
  final ExpertProfileProvider provider;
  final Map<String, dynamic>? experience;

  const ExperienceSheet({
    super.key,
    required this.provider,
    this.experience,
  });

  @override
  State<ExperienceSheet> createState() => _ExperienceSheetState();
}

class _ExperienceSheetState extends State<ExperienceSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController job, company, location, description;
  String? employmentType;
  String? startDate, endDate;
  bool isCurrent = false;

  @override
  void initState() {
    super.initState();
    final e = widget.experience;

    job = TextEditingController(text: e?['job_title'] ?? '');
    company = TextEditingController(text: e?['company'] ?? '');
    location = TextEditingController(text: e?['location'] ?? '');
    description = TextEditingController(text: e?['description'] ?? '');
    employmentType = e?['employment_type'];
    startDate = e?['start_date'];
    endDate = e?['end_date'];
    isCurrent = endDate == null && widget.experience != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.experience == null
                  ? 'Add Experience'
                  : 'Edit Experience',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const FormSectionTitle('Role Details'),
            ProfileTextField(
              controller: job,
              label: 'Job Title',
              icon: Icons.work_outline,
            ),
            ProfileTextField(
              controller: company,
              label: 'Company',
              icon: Icons.apartment,
            ),
            DropdownButtonFormField<String>(
              value: employmentType,
              decoration: InputDecoration(
                labelText: 'Employment Type',
                prefixIcon: const Icon(Icons.badge_outlined),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: employmentTypes.map((e) {
                return DropdownMenuItem<String>(
                  value: e['value'],
                  child: Text(e['label']!),
                );
              }).toList(),
              onChanged: (v) => setState(() => employmentType = v),
            ),
            ProfileTextField(
              controller: location,
              label: 'Location',
              icon: Icons.location_on,
            ),
            ProfileDateField(
              label: 'Start Date',
              icon: Icons.calendar_today_outlined,
              value: startDate,
              onTap: () async {
                final d = await pickDate(context);
                if (d != null) setState(() => startDate = d);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Currently working here'),
              value: isCurrent,
              onChanged: (v) {
                setState(() {
                  isCurrent = v;
                  if (v) endDate = null;
                });
              },
            ),
            if (!isCurrent)
              ProfileDateField(
                label: 'End Date',
                icon: Icons.event_outlined,
                value: endDate,
                onTap: () async {
                  final d = await pickDate(context);
                  if (d != null) setState(() => endDate = d);
                },
              ),
            ProfileTextField(
              controller: description,
              label: 'Description',
              icon: Icons.notes,
              maxLines: 3,
              requiredField: false,
            ),
            BottomSheetSaveButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                if (startDate == null) return;

                final data = {
                  "job_title": job.text.trim(),
                  "company": company.text.trim(),
                  "employment_type": employmentType,
                  "location": location.text.trim(),
                  "start_date": startDate,
                  "end_date": isCurrent ? null : endDate,
                  "description": description.text.trim(),
                };

                widget.experience == null
                    ? await widget.provider.addExperience(data)
                    : await widget.provider.updateExperience(
                        widget.experience!['id'],
                        data,
                      );

                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

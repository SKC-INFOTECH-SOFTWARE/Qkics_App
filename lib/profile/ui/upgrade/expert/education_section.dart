import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/profile/ui/widgets/profile_form_fields.dart';
import 'package:q_kics/profile/utils/bottom_sheet_utils.dart';
import 'package:q_kics/providers/expert_profile_provider.dart';

class EducationSection extends StatefulWidget {
  final List<Map<String, dynamic>>? publicEducations;
  final bool isPublicView;

  const EducationSection({
    super.key,
    this.publicEducations,
    this.isPublicView = false,
  });

  @override
  State<EducationSection> createState() => _EducationSectionState();
}

class _EducationSectionState extends State<EducationSection> {
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
            widget.publicEducations ?? const [],
          )
        : context.watch<ExpertProfileProvider>().educations;

    list.sort(
      (a, b) =>
          (b['start_year'] ?? 0).compareTo(a['start_year'] ?? 0),
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
                  (i) => _educationCard(context, list[i], i),
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
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.school_outlined,
            color: theme.colorScheme.primary),
      ),
      title: Text(
        'Education',
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
  // EDUCATION CARD (SMOOTH)
  // ============================================================
  Widget _educationCard(
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
        // margin: const EdgeInsets.only(bottom: 12),
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
                        e['degree'] ?? '',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e['school'] ?? '',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${e['start_year']} - ${e['end_year'] ?? 'Present'}',
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
                      padding:
                          const EdgeInsets.only(top: 14),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (e['field_of_study']?.isNotEmpty == true)
            _row(
              theme,
              Icons.auto_stories,
              'Field',
              e['field_of_study'],
            ),
          if (e['grade']?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _row(
              theme,
              Icons.grade_outlined,
              'Grade',
              e['grade'],
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
          _openSheet(context, provider, education: e);
        } else {
          provider.deleteEducation(e['id']);
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
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.school_outlined,
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
    Map<String, dynamic>? education,
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
          EducationSheet(provider: provider, education: education),
    );
  }
}

/// ===============================================================
/// EDUCATION SHEET (LOGIC UNCHANGED)
/// ===============================================================
class EducationSheet extends StatefulWidget {
  final ExpertProfileProvider provider;
  final Map<String, dynamic>? education;

  const EducationSheet({
    super.key,
    required this.provider,
    this.education,
  });

  @override
  State<EducationSheet> createState() => _EducationSheetState();
}

class _EducationSheetState extends State<EducationSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController school, degree, field, grade, description;
  int? startYear, endYear;
  bool isCurrent = false;

  @override
  void initState() {
    super.initState();
    final e = widget.education;

    school = TextEditingController(text: e?['school'] ?? '');
    degree = TextEditingController(text: e?['degree'] ?? '');
    field = TextEditingController(text: e?['field_of_study'] ?? '');
    grade = TextEditingController(text: e?['grade'] ?? '');
    description = TextEditingController(text: e?['description'] ?? '');

    startYear = e?['start_year'];
    endYear = e?['end_year'];
    isCurrent = endYear == null && widget.education != null;
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
              widget.education == null
                  ? 'Add Education'
                  : 'Edit Education',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const FormSectionTitle('Academic Details'),
            ProfileTextField(
              controller: school,
              label: 'School / University',
              icon: Icons.school_outlined,
            ),
            ProfileTextField(
              controller: degree,
              label: 'Degree',
              icon: Icons.menu_book,
            ),
            ProfileTextField(
              controller: field,
              label: 'Field of Study',
              icon: Icons.auto_stories,
            ),
            ProfileTextField(
              controller: grade,
              label: 'Grade (optional)',
              icon: Icons.grade,
              requiredField: false,
            ),
            const FormSectionTitle('Duration'),
            ProfileDateField(
              label: 'Start Year',
              icon: Icons.calendar_today_outlined,
              value: startYear?.toString(),
              onTap: () async {
                final y = await _pickYear(context, startYear);
                if (y != null) setState(() => startYear = y);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Currently studying here'),
              value: isCurrent,
              onChanged: (v) {
                setState(() {
                  isCurrent = v;
                  if (v) endYear = null;
                });
              },
            ),
            if (!isCurrent)
              ProfileDateField(
                label: 'End Year',
                icon: Icons.event_outlined,
                value: endYear?.toString(),
                onTap: () async {
                  final y = await _pickYear(context, endYear);
                  if (y != null) setState(() => endYear = y);
                },
              ),
            ProfileTextField(
              controller: description,
              label: 'Description (optional)',
              icon: Icons.notes,
              maxLines: 3,
              requiredField: false,
            ),
            BottomSheetSaveButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                if (startYear == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Please select start year')),
                  );
                  return;
                }

                final data = {
                  "school": school.text.trim(),
                  "degree": degree.text.trim(),
                  "field_of_study": field.text.trim(),
                  "start_year": startYear,
                  "end_year": isCurrent ? null : endYear,
                  "grade": grade.text.trim(),
                  "description": description.text.trim(),
                };

                widget.education == null
                    ? await widget.provider.addEducation(data)
                    : await widget.provider.updateEducation(
                        widget.education!['id'],
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

  Future<int?> _pickYear(BuildContext context, int? initialYear) async {
    final now = DateTime.now().year;
    int selectedYear = initialYear ?? now;

    return showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select Year',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: YearPicker(
                  firstDate: DateTime(1950),
                  lastDate: DateTime(now + 1),
                  selectedDate: DateTime(selectedYear),
                  onChanged: (date) {
                    Navigator.pop(context, date.year);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

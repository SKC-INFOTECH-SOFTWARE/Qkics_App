import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/profile/ui/widgets/profile_form_fields.dart';
import 'package:q_kics/profile/utils/bottom_sheet_utils.dart';
import 'package:q_kics/providers/expert_profile_provider.dart';

class HonorSection extends StatefulWidget {
  final List<Map<String, dynamic>>? publicHonors;
  final bool isPublicView;

  const HonorSection({
    super.key,
    this.publicHonors,
    this.isPublicView = false,
  });

  @override
  State<HonorSection> createState() => _HonorSectionState();
}

class _HonorSectionState extends State<HonorSection> {
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
            widget.publicHonors ?? const [],
          )
        : context.watch<ExpertProfileProvider>().honors;

    list.sort(
      (a, b) =>
          (b['issue_date'] ?? '').compareTo(a['issue_date'] ?? ''),
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
                  (i) => _honorCard(context, list[i], i),
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
        child: Icon(Icons.emoji_events,
            color: theme.colorScheme.primary),
      ),
      title: Text(
        'Honors & Awards',
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
  // HONOR CARD
  // ============================================================
  Widget _honorCard(
    BuildContext context,
    Map<String, dynamic> h,
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
                  child: Text(
                    h['title'] ?? '',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more),
                ),
                if (!widget.isPublicView)
                  _menu(context, h),
              ],
            ),

            // ================= DETAILS =================
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isOpen
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _details(theme, h),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAILS CARD (ISSUER + DATE + DESCRIPTION)
  // ============================================================
  Widget _details(ThemeData theme, Map<String, dynamic> h) {
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
            Icons.apartment,
            'Issuer',
            h['issuer'],
          ),
          const SizedBox(height: 8),
          _row(
            theme,
            Icons.calendar_today_outlined,
            'Issue Date',
            h['issue_date'],
          ),
          if (h['description']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _row(
              theme,
              Icons.notes_outlined,
              'Description',
              h['description'],
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
  Widget _menu(BuildContext context, Map<String, dynamic> h) {
    final provider = context.read<ExpertProfileProvider>();
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (v) {
        if (v == 'edit') {
          _openSheet(context, provider, honor: h);
        } else {
          provider.deleteHonor(h['id']);
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
      child: Icon(Icons.emoji_events,
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
    Map<String, dynamic>? honor,
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
          HonorSheet(provider: provider, honor: honor),
    );
  }
}

// ============================================================
// BOTTOM SHEET (UNCHANGED LOGIC)
// ============================================================

class HonorSheet extends StatefulWidget {
  final ExpertProfileProvider provider;
  final Map<String, dynamic>? honor;

  const HonorSheet({
    super.key,
    required this.provider,
    this.honor,
  });

  @override
  State<HonorSheet> createState() => _HonorSheetState();
}

class _HonorSheetState extends State<HonorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController title, issuer, description;
  String? issueDate;

  @override
  void initState() {
    super.initState();
    final h = widget.honor;
    title = TextEditingController(text: h?['title'] ?? '');
    issuer = TextEditingController(text: h?['issuer'] ?? '');
    description = TextEditingController(text: h?['description'] ?? '');
    issueDate = h?['issue_date'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              widget.honor == null
                  ? 'Add Honor / Award'
                  : 'Edit Honor / Award',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const FormSectionTitle('Award Details'),
            ProfileTextField(
              controller: title,
              label: 'Title',
              icon: Icons.emoji_events,
            ),
            ProfileTextField(
              controller: issuer,
              label: 'Issuer',
              icon: Icons.apartment,
            ),
            ProfileDateField(
              label: 'Issue Date',
              icon: Icons.calendar_today_outlined,
              value: issueDate,
              onTap: () async {
                final d = await pickDate(context);
                if (d != null) setState(() => issueDate = d);
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
                if (!_formKey.currentState!.validate() ||
                    issueDate == null) return;

                final data = {
                  "title": title.text.trim(),
                  "issuer": issuer.text.trim(),
                  "issue_date": issueDate,
                  "description": description.text.trim(),
                };

                widget.honor == null
                    ? await widget.provider.addHonor(data)
                    : await widget.provider.updateHonor(
                        widget.honor!['id'],
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

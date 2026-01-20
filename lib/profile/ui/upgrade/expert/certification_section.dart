import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/profile/ui/widgets/profile_form_fields.dart';
import 'package:q_kics/profile/utils/bottom_sheet_utils.dart';
import 'package:q_kics/providers/expert_profile_provider.dart';
// import 'package:url_launcher/url_launcher.dart'; // ← enable if needed

class CertificationSection extends StatefulWidget {
  final List<Map<String, dynamic>>? publicCertifications;
  final bool isPublicView;

  const CertificationSection({
    super.key,
    this.publicCertifications,
    this.isPublicView = false,
  });

  @override
  State<CertificationSection> createState() => _CertificationSectionState();
}

class _CertificationSectionState extends State<CertificationSection> {
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
            widget.publicCertifications ?? const [],
          )
        : context.watch<ExpertProfileProvider>().certifications;

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
                  (i) => _certCard(context, list[i], i),
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
        child: Icon(Icons.workspace_premium,
            color: theme.colorScheme.primary),
      ),
      title: Text(
        'Certifications',
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
  // CERT CARD (FIXED INTERACTION)
  // ============================================================
  Widget _certCard(
    BuildContext context,
    Map<String, dynamic> c,
    int index,
  ) {
    final theme = Theme.of(context);
    final isOpen = _openCards.contains(index);

    final isExpired = c['expiration_date'] != null &&
        DateTime.tryParse(c['expiration_date']) != null &&
        DateTime.parse(c['expiration_date'])
            .isBefore(DateTime.now());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      //margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpired
              ? Colors.red.withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= HEADER (ONLY THIS TOGGLES) =================
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                isOpen
                    ? _openCards.remove(index)
                    : _openCards.add(index);
              });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // _icon(theme),
                // const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['name'] ?? '',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c['issuing_organization'] ?? '',
                        style: theme.textTheme.bodySmall
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
                  _menu(context, c),
              ],
            ),
          ),

          // ================= DETAILS =================
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isOpen
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _details(theme, c, isExpired),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAILS (LINK SAFE)
  // ============================================================
  Widget _details(
    ThemeData theme,
    Map<String, dynamic> c,
    bool expired,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill(
                theme,
                Icons.calendar_today_outlined,
                'Issued ${c['issue_date']}',
              ),
              if (c['expiration_date'] != null)
                _pill(
                  theme,
                  expired
                      ? Icons.warning_amber_rounded
                      : Icons.event_busy_outlined,
                  expired
                      ? 'Expired ${c['expiration_date']}'
                      : 'Expires ${c['expiration_date']}',
                  color: expired ? Colors.red : null,
                ),
            ],
          ),
          if (c['credential_id']?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _row(
              theme,
              Icons.badge_outlined,
              'Credential ID',
              c['credential_id'],
            ),
          ],
          if (c['credential_url']?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _row(
              theme,
              Icons.link,
              'Credential URL',
              c['credential_url'],
              link: true,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // MENU
  // ============================================================
  Widget _menu(BuildContext context, Map<String, dynamic> c) {
    final provider = context.read<ExpertProfileProvider>();
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (v) {
        if (v == 'edit') {
          _openSheet(context, provider, certification: c);
        } else {
          provider.deleteCertification(c['id']);
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
      child: Icon(Icons.workspace_premium,
          color: theme.colorScheme.primary),
    );
  }

  Widget _pill(
    ThemeData theme,
    IconData icon,
    String label, {
    Color? color,
  }) {
    final c = color ?? theme.colorScheme.primary;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    IconData icon,
    String label,
    String value, {
    bool link = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.hintColor),
        const SizedBox(width: 6),
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
                WidgetSpan(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: link
                        ? () async {
                            // final uri = Uri.parse(value);
                            // if (await canLaunchUrl(uri)) {
                            //   launchUrl(uri);
                            // }
                          }
                        : null,
                    child: Text(
                      value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: link
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodySmall?.color,
                        decoration:
                            link ? TextDecoration.underline : null,
                      ),
                    ),
                  ),
                ),
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
    Map<String, dynamic>? certification,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CertificationSheet(
        provider: provider,
        certification: certification,
      ),
    );
  }
}

// ============================================================
// BOTTOM SHEET (UNCHANGED LOGIC)
// ============================================================

class CertificationSheet extends StatefulWidget {
  final ExpertProfileProvider provider;
  final Map<String, dynamic>? certification;

  const CertificationSheet({
    super.key,
    required this.provider,
    this.certification,
  });

  @override
  State<CertificationSheet> createState() =>
      _CertificationSheetState();
}

class _CertificationSheetState extends State<CertificationSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController name, organization, credential, credentialUrl;
  String? issueDate, expirationDate;

  @override
  void initState() {
    super.initState();
    final c = widget.certification;
    name = TextEditingController(text: c?['name'] ?? '');
    organization =
        TextEditingController(text: c?['issuing_organization'] ?? '');
    credential = TextEditingController(text: c?['credential_id'] ?? '');
    credentialUrl =
        TextEditingController(text: c?['credential_url'] ?? '');
    issueDate = c?['issue_date'];
    expirationDate = c?['expiration_date'];
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
              widget.certification == null
                  ? 'Add Certification'
                  : 'Edit Certification',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const FormSectionTitle('Certification Details'),
            ProfileTextField(
              controller: name,
              label: 'Certification Name',
              icon: Icons.workspace_premium,
            ),
            ProfileTextField(
              controller: organization,
              label: 'Issuing Organization',
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
            ProfileDateField(
              label: 'Expiration Date (optional)',
              icon: Icons.event_busy_outlined,
              value: expirationDate,
              onTap: () async {
                final d = await pickDate(context);
                if (d != null) setState(() => expirationDate = d);
              },
            ),
            ProfileTextField(
              controller: credential,
              label: 'Credential ID (optional)',
              icon: Icons.badge_outlined,
              requiredField: false,
            ),
            ProfileTextField(
              controller: credentialUrl,
              label: 'Credential URL (optional)',
              icon: Icons.link,
              requiredField: false,
            ),
            BottomSheetSaveButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate() ||
                    issueDate == null) return;

                final data = {
                  "name": name.text.trim(),
                  "issuing_organization":
                      organization.text.trim(),
                  "issue_date": issueDate,
                  "expiration_date": expirationDate,
                  "credential_id": credential.text.trim(),
                  "credential_url":
                      credentialUrl.text.trim(),
                };

                widget.certification == null
                    ? await widget.provider.addCertification(data)
                    : await widget.provider.updateCertification(
                        widget.certification!['id'],
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

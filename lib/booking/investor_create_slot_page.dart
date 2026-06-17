import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:q_kics/providers/booking_provider.dart';
import 'package:q_kics/booking/models/investor_slot.dart';

class InvestorCreateSlotPage extends StatefulWidget {
  const InvestorCreateSlotPage({super.key});

  @override
  State<InvestorCreateSlotPage> createState() => _InvestorCreateSlotPageState();
}

class _InvestorCreateSlotPageState extends State<InvestorCreateSlotPage> {
  DateTime? start;
  DateTime? end;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchInvestorSlots();
    });
  }

  // ================= DATE PICKERS =================

  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: start ?? now,
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        start ?? now.add(const Duration(minutes: 15)),
      ),
    );
    if (time == null) return;

    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (picked.isBefore(now)) {
      _showMessage("Start time must be in the future");
      return;
    }

    setState(() {
      start = picked;
      if (end != null && end!.isBefore(start!)) {
        end = null;
      }
    });
  }

  Future<void> _pickEndTime() async {
    if (start == null) {
      _showMessage("Select start time first");
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        end ?? start!.add(const Duration(minutes: 30)),
      ),
    );
    if (time == null) return;

    final picked = DateTime(
      start!.year,
      start!.month,
      start!.day,
      time.hour,
      time.minute,
    );

    if (!picked.isAfter(start!)) {
      _showMessage("End time must be after start time");
      return;
    }

    setState(() => end = picked);
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Investor Slots"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= CREATE FORM =================
            _SectionCard(
              title: "Create Slot",
              child: Column(
                children: [
                  _TimeField(
                    icon: Icons.play_arrow,
                    label: "Start",
                    value: start == null
                        ? "Select start date & time"
                        : DateFormat('dd MMM yyyy • hh:mm a').format(start!),
                    onTap: _pickStartDateTime,
                  ),
                  const SizedBox(height: 12),
                  _TimeField(
                    icon: Icons.stop,
                    label: "End",
                    value: end == null
                        ? "Select end time"
                        : DateFormat('hh:mm a').format(end!),
                    onTap: _pickEndTime,
                  ),
                  if (start != null && end != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Duration: ${end!.difference(start!).inMinutes} minutes",
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= SLOT LIST =================
            Text(
              "Your Slots",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.investorSlots.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text("No slots created yet"),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.investorSlots.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final slot = provider.investorSlots[i];
                  return _SlotTile(slot: slot);
                },
              ),

            const SizedBox(height: 120),
          ],
        ),
      ),

      // ================= CREATE BUTTON =================
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: provider.isLoading
                ? null
                : () async {
                    if (start == null || end == null) {
                      _showMessage("Select start & end time");
                      return;
                    }

                    await provider.createInvestorSlot(
                      start: start!,
                      end: end!,
                      duration: end!.difference(start!).inMinutes,
                    );

                    setState(() {
                      start = null;
                      end = null;
                    });
                    _showMessage("Slot created successfully!");
                  },
            child: provider.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "Create Slot",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ===================================================================
// SLOT TILE
// ===================================================================

class _SlotTile extends StatelessWidget {
  final InvestorSlot slot;
  const _SlotTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd MMM yyyy').format(slot.startDateTime.toLocal()),
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              "${DateFormat.jm().format(slot.startDateTime.toLocal())} - "
              "${DateFormat.jm().format(slot.endDateTime.toLocal())}",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${slot.durationMinutes} mins",
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
/// SMALL UI WIDGETS
//////////////////////////////////////////////////////////////

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }
}

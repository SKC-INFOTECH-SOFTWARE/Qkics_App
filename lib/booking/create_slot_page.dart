import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:q_kics/providers/booking_provider.dart';
import 'package:q_kics/booking/models/expert_slot.dart';

class CreateSlotPage extends StatefulWidget {
  const CreateSlotPage({super.key});

  @override
  State<CreateSlotPage> createState() => _CreateSlotPageState();
}

class _CreateSlotPageState extends State<CreateSlotPage> {
  DateTime? start;
  DateTime? end;
  final TextEditingController priceCtrl = TextEditingController();
  bool approval = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchSlots();
    });
  }

  @override
  void dispose() {
    priceCtrl.dispose();
    super.dispose();
  }

  ExpertSlot? _editingSlot;

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
      // If end is before new start, clear it
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

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Slots"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= CREATE / EDIT FORM =================
            _SectionCard(
              title: _editingSlot == null ? "Create Slot" : "Edit Slot",
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
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Price",
                      prefixText: "₹ ",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    value: approval,
                    onChanged: (v) => setState(() => approval = v),
                    title: const Text("Requires admin approval"),
                  ),
                  if (_editingSlot != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: _clearForm,
                        icon: const Icon(Icons.close),
                        label: const Text("Cancel Edit"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
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
            else if (provider.slots.isEmpty)
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
                itemCount: provider.slots.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final slot = provider.slots[i];
                  final booked = !slot.isAvailable;
                  final isEditing = _editingSlot?.uuid == slot.uuid;

                  return Card(
                    color: isEditing
                        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: isEditing
                          ? BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(slot.startDateTime),
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${DateFormat.jm().format(slot.startDateTime)} - "
                            "${DateFormat.jm().format(slot.endDateTime)}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _Chip("₹${slot.price}"),
                              const SizedBox(width: 8),
                              _Chip("${slot.durationMinutes} mins"),
                              const Spacer(),
                              _StatusBadge(booked: booked),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text("Edit"),
                                  onPressed: booked || isEditing
                                      ? null
                                      : () => _populateForm(slot),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.delete),
                                  label: const Text("Delete"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  onPressed: booked
                                      ? null
                                      : () async {
                                          final ok = await _confirm(
                                            "Delete Slot?",
                                          );
                                          if (ok) {
                                            await context
                                                .read<BookingProvider>()
                                                .deleteSlot(slot.uuid);
                                          }
                                        },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 120),
          ],
        ),
      ),

      // ================= CREATE / UPDATE BUTTON =================
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

                    final price = double.tryParse(priceCtrl.text.trim());
                    if (price == null || price <= 0) {
                      _showMessage("Enter valid price");
                      return;
                    }

                    if (_editingSlot != null) {
                      // UPDATE
                      await provider.updateSlot(
                        slotUuid: _editingSlot!.uuid,
                        start: start!,
                        end: end!,
                        price: price,
                        requiresApproval: approval,
                      );
                      _clearForm();
                      _showMessage("Slot updated successfully");
                    } else {
                      // CREATE
                      await provider.createSlot(
                        start: start!,
                        end: end!,
                        duration: end!.difference(start!).inMinutes,
                        price: price,
                        requiresApproval: approval,
                      );
                      _clearForm();
                      _showMessage("Slot created successfully");
                    }
                  },
            child: provider.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _editingSlot != null ? "Update Slot" : "Create Slot",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================

  void _populateForm(ExpertSlot slot) {
    setState(() {
      _editingSlot = slot;
      start = slot.startDateTime;
      end = slot.endDateTime;
      priceCtrl.text = slot.price.toString();
      approval = slot.requiresApproval;
    });
    // Optional: Scroll to top
  }

  void _clearForm() {
    setState(() {
      _editingSlot = null;
      start = null;
      end = null;
      priceCtrl.clear();
      approval = true;
    });
  }

  Future<bool> _confirm(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: const Text("Are you sure?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

//////////////////////////////////////////////////////////////
/// EDIT SLOT BOTTOM SHEET
//////////////////////////////////////////////////////////////

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

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool booked;
  const _StatusBadge({required this.booked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: booked
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        booked ? "Booked" : "Available",
        style: TextStyle(
          fontSize: 12,
          color: booked ? Colors.red : Colors.green,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

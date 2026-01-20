import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/profile/models/user_profile_model.dart';
import 'package:q_kics/providers/profile_provider.dart';

class EditbasicProfileSheet extends StatefulWidget {
  final UserProfile profile;

  const EditbasicProfileSheet({super.key, required this.profile});

  @override
  State<EditbasicProfileSheet> createState() => _EditbasicProfileSheetState();
}

class _EditbasicProfileSheetState extends State<EditbasicProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController firstName;
  late TextEditingController lastName;
  late TextEditingController phone;

  File? selectedImage;

  @override
  void initState() {
    super.initState();
    firstName = TextEditingController(text: widget.profile.firstName);
    lastName = TextEditingController(text: widget.profile.lastName);
    phone = TextEditingController(text: widget.profile.phone);
  }

  @override
  void dispose() {
    firstName.dispose();
    lastName.dispose();
    phone.dispose();
    super.dispose();
  }

  // ================= IMAGE PICK =================
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  // ================= IMAGE PROVIDER =================
  ImageProvider? _avatarProvider() {
    if (selectedImage != null) {
      return FileImage(selectedImage!);
    }

    if (widget.profile.profilePicture != null &&
        widget.profile.profilePicture!.isNotEmpty) {
      // 🔥 Cache busting
      return NetworkImage(
        '${widget.profile.profilePicture}?v=${DateTime.now().millisecondsSinceEpoch}',
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = context.watch<ProfileProvider>();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            // ================= DRAG HANDLE =================
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ================= TITLE =================
            Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // ================= AVATAR =================
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: _avatarProvider(),
                        child: _avatarProvider() == null
                            ? Text(
                                widget.profile.initial,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 20,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ================= FIELDS =================
            Row(
              children: [
                Expanded(
                  child: _field(firstName, 'First Name', Icons.person_outline),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _field(lastName, 'Last Name', Icons.person_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _field(phone, 'Phone Number', Icons.phone_outlined),

            const SizedBox(height: 32),

            // ================= SAVE =================
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: provider.loadingProfile
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;

                        await provider.updateMyProfile(
                          firstName: firstName.text.trim(),
                          lastName: lastName.text.trim(),
                          phone: phone.text.trim(),
                          image: selectedImage,
                        );

                        if (context.mounted) Navigator.pop(context);
                      },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: provider.loadingProfile
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ================= INPUT FIELD =================
  Widget _field(TextEditingController controller, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            icon,
            size: 22,
            color: Theme.of(context).colorScheme.primary,
          ),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceVariant.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:q_kics/profile/ui/upgrade/entrepreneur/entrepreneur_profile_form.dart';
import 'package:q_kics/profile/ui/upgrade/expert/expert_profile_form.dart';


class ChooseProfileTypeSheet extends StatelessWidget {
  const ChooseProfileTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upgrade Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            _option(
              context,
              title: 'Expert',
              subtitle: 'Offer paid expertise & get verified',
              icon: Icons.school,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExpertProfileForm(),
                  ),
                );
              },
            ),

            _option(
              context,
              title: 'Entrepreneur',
              subtitle: 'Showcase your startup & raise credibility',
              icon: Icons.business_center,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EntrepreneurProfileForm(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

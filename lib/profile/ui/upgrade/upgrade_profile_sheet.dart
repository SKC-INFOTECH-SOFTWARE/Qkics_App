import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/profile/ui/upgrade/entrepreneur/entrepreneur_profile_form.dart';
import 'package:q_kics/profile/ui/upgrade/expert/expert_profile_form.dart';
import 'package:q_kics/providers/expert_profile_provider.dart';

class UpgradeProfileSheet extends StatelessWidget {
  const UpgradeProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Become Expert'),
            subtitle: const Text('Offer consultations & answers'),
            onTap: () {
               Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<ExpertProfileProvider>(),
      child: const ExpertProfileForm(),
    ),
  ),
);

            }
          
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Become Entrepreneur'),
            subtitle: const Text('Showcase your startup'),
           onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EntrepreneurProfileForm()),
              );
            }
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class UpgradeProfileCard extends StatelessWidget {
  const UpgradeProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ListTile(
        title: const Text('Upgrade Profile'),
        subtitle: const Text('Become an Expert or Entrepreneur'),
        trailing: ElevatedButton(
          onPressed: () {
            // navigate to upgrade flow
          },
          child: const Text('Upgrade'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ProfileCompletionCard extends StatelessWidget {
  final double progress; // 0.0 → 1.0
  final List<String> suggestions;

  const ProfileCompletionCard({
    super.key,
    required this.progress,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();
    final bool isComplete = percent >= 100;

    final Color progressColor =
        isComplete ? Colors.green : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= TITLE =================
            Text(
              'Profile Completion',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),

            // ================= PROGRESS BAR =================
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceVariant,
                valueColor:
                    AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),

            const SizedBox(height: 8),

            // ================= PERCENT TEXT =================
            Text(
              isComplete ? '100% completed 🎉' : '$percent% complete',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isComplete ? Colors.green : null,
                  ),
            ),

            // ================= SUGGESTIONS =================
            if (suggestions.isNotEmpty && !isComplete) ...[
              const SizedBox(height: 14),
              const Text(
                'Improve your profile:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...suggestions.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.arrow_right,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(s)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

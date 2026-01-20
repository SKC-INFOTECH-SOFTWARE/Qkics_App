import 'package:flutter/material.dart';

class AnswersTab extends StatelessWidget {
  const AnswersTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder – plug Answer API later
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to grow a startup in 2025?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Focus on customer retention, automation, and AI-driven decisions.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.thumb_up_alt_outlined, size: 16),
                    SizedBox(width: 6),
                    Text('12'),
                    Spacer(),
                    Text(
                      '2 days ago',
                      style: TextStyle(fontSize: 12),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

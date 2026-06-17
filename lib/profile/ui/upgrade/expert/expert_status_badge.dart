import 'package:flutter/material.dart';

class ExpertStatusBadge extends StatelessWidget {
  final bool verified;
  final String status;
  final String? adminNote;

  const ExpertStatusBadge({
    super.key,
    required this.verified,
    required this.status,
    this.adminNote,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = Colors.green;
        label = 'Approved Expert';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.orange;
        label = 'Pending Review';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            if (verified)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.verified, color: Colors.blue, size: 20),
              ),
          ],
        ),
        if (status == 'rejected' && adminNote != null) ...[
          const SizedBox(height: 8),
          Text(
            'Admin Note: $adminNote',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ],
      ],
    );
  }
}

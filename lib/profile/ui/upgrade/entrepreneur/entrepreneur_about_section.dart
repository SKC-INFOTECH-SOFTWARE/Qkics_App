import 'package:flutter/material.dart';

class EntrepreneurAboutSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const EntrepreneurAboutSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['startup_name'],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          data['one_liner'],
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        _row('Industry', data['industry']),
        _row('Location', data['location']),
        _row('Funding Stage', data['funding_stage']),
        if (data['website'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: () {},
              child: Text(
                data['website'],
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

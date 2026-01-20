import 'package:flutter/material.dart';

class SubmitForReviewButton extends StatelessWidget {
  const SubmitForReviewButton({super.key, required Future<Null> Function() onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // show dialog -> submit note
        
      },
      child: const Text('Submit for Admin Review'),
    );
  }
}

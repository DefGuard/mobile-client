import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/next/next_code_entry_layout.dart';

class NextMfaEmailScreen extends StatelessWidget {
  final NextCodeEntrySubmit onSubmit;

  const NextMfaEmailScreen({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return NextCodeEntryLayout(
      title: 'Two-factor authentication',
      description: 'Paste the authentication code you received in the email.',
      fieldLabel: 'Authentication Code',
      onSubmit: onSubmit,
    );
  }
}

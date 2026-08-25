import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/next/next_code_entry_layout.dart';

class NextMfaTotpScreen extends StatelessWidget {
  final NextCodeEntrySubmit onSubmit;

  const NextMfaTotpScreen({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return NextCodeEntryLayout(
      title: 'Two-factor authentication',
      description:
          'Paste the authentication code from your Authenticator Application.',
      fieldLabel: 'Authentication Code',
      onSubmit: onSubmit,
    );
  }
}

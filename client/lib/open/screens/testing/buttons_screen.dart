import 'package:flutter/material.dart';
import 'package:mobile/open/widgets/next/next_button.dart';
import 'package:mobile/theme/next/spacing.dart';

class ButtonsTestingScreen extends StatelessWidget {
  const ButtonsTestingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -1.0),
            end: Alignment(0.7, 1.0),
            colors: [
              Color(0xff5B83FF),
              Color(0xff0036DB),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NextSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'NextButton Variants',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NextSpacing.xl),
                ..._buildAllVariants(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAllVariants() {
    final List<Widget> sections = [];

    for (final style in NextButtonStyle.values) {
      sections.add(
        Padding(
          padding: const EdgeInsets.only(top: NextSpacing.xl, bottom: NextSpacing.sm),
          child: Text(
            'Style: ${style.name.toUpperCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

      for (final size in NextButtonSize.values) {
        sections.add(
          Padding(
            padding: const EdgeInsets.only(top: NextSpacing.md, bottom: NextSpacing.sm),
            child: Text(
              'Size: ${size.name}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
        );

        sections.add(
          Column(
            children: [
              NextButton(
                text: 'Normal ${style.name} ${size.name}',
                style: style,
                size: size,
                onTap: () {},
              ),
              const SizedBox(height: NextSpacing.sm),
              NextButton(
                text: 'Loading ${style.name} ${size.name}',
                style: style,
                size: size,
                loading: true,
                onTap: () {},
              ),
              const SizedBox(height: NextSpacing.sm),
              NextButton(
                text: 'Disabled ${style.name} ${size.name}',
                style: style,
                size: size,
                disabled: true,
                onTap: () {},
              ),
              const SizedBox(height: NextSpacing.sm),
              NextButton(
                text: 'With Icon ${style.name} ${size.name}',
                style: style,
                size: size,
                icon: const Icon(Icons.star, color: Colors.white, size: 18),
                onTap: () {},
              ),
            ],
          ),
        );
      }
    }

    return sections;
  }
}

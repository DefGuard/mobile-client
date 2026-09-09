import 'package:material_ui/material_ui.dart';
import 'package:mobile/theme/color.dart';
import 'package:mobile/theme/text.dart';

/// Renders `Step 2/3` above a step's title, and nothing at all when the flow
/// has a single step.
class DgMfaStepLabel extends StatelessWidget {
  final String? label;

  const DgMfaStepLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: DgText.bodyXs500.copyWith(color: DgColor.fgWhite60),
      ),
    );
  }
}

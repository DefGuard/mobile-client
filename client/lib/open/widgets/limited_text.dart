import 'package:material_ui/material_ui.dart';

class LimitedText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const LimitedText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: style,
      ),
    );
  }
}

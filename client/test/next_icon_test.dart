import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/open/widgets/next/icons/next_icon.dart';
import 'package:mobile/theme/next/color.dart';

void main() {
  group('NextIcon', () {
    test('constructs asset path correctly', () {
      const icon1 = NextIcon('arrow_small');
      expect(icon1.assetPath, equals('assets/next/icons/arrow_small.svg'));

      const icon2 = NextIcon('arrow_small.svg');
      expect(icon2.assetPath, equals('assets/next/icons/arrow_small.svg'));

      const icon3 = NextIcon('assets/next/icons/arrow_small.svg');
      expect(icon3.assetPath, equals('assets/next/icons/arrow_small.svg'));
    });

    test('default properties are set correctly', () {
      const icon = NextIcon('check');
      expect(icon.size, equals(20.0));
      expect(icon.color, equals(NextColor.fgAction));
      expect(icon.rotation, equals(0.0));
      expect(icon.direction, isNull);
      expect(icon.effectiveRotation, equals(0.0));
    });

    test('calculates direction rotation clockwise from base direction (right)', () {
      const iconRight = NextIcon('arrow_small', direction: NextIconDirection.right);
      expect(iconRight.effectiveRotation, equals(0.0));

      const iconDown = NextIcon('arrow_small', direction: NextIconDirection.down);
      expect(iconDown.effectiveRotation, closeTo(math.pi / 2, 0.0001)); // 90 degrees

      const iconLeft = NextIcon('arrow_small', direction: NextIconDirection.left);
      expect(iconLeft.effectiveRotation, closeTo(math.pi, 0.0001)); // 180 degrees

      const iconUp = NextIcon('arrow_small', direction: NextIconDirection.up);
      expect(iconUp.effectiveRotation, closeTo(3 * math.pi / 2, 0.0001)); // 270 degrees
    });

    test('arrow_big rotation works for all directions', () {
      const iconDown = NextIcon('arrow_big', direction: NextIconDirection.down);
      expect(iconDown.effectiveRotation, closeTo(math.pi / 2, 0.0001));
    });

    test('static base direction registration works correctly', () {
      NextIcon.registerBaseDirection('chevron', NextIconDirection.up);

      const iconUp = NextIcon('chevron', direction: NextIconDirection.up);
      expect(iconUp.effectiveRotation, equals(0.0));

      const iconRight = NextIcon('chevron', direction: NextIconDirection.right);
      expect(iconRight.effectiveRotation, closeTo(math.pi / 2, 0.0001));
    });

    test('copyWith updates direction property correctly', () {
      const icon = NextIcon('arrow_small');
      final updated = icon.copyWith(
        direction: NextIconDirection.down,
      );

      expect(updated.direction, equals(NextIconDirection.down));
      expect(updated.effectiveRotation, closeTo(math.pi / 2, 0.0001));
    });
  });
}

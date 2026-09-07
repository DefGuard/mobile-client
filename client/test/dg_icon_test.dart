import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/open/widgets/icons/dg_icon.dart';
import 'package:mobile/theme/color.dart';

void main() {
  group('DgIcon', () {
    test('constructs asset path correctly', () {
      const icon1 = DgIcon('arrow_small');
      expect(icon1.assetPath, equals('assets/next/icons/arrow_small.svg'));

      const icon2 = DgIcon('arrow_small.svg');
      expect(icon2.assetPath, equals('assets/next/icons/arrow_small.svg'));

      const icon3 = DgIcon('assets/next/icons/arrow_small.svg');
      expect(icon3.assetPath, equals('assets/next/icons/arrow_small.svg'));
    });

    test('default properties are set correctly', () {
      const icon = DgIcon('check');
      expect(icon.size, equals(20.0));
      expect(icon.color, equals(DgColor.fgAction));
      expect(icon.rotation, equals(0.0));
      expect(icon.direction, isNull);
      expect(icon.effectiveRotation, equals(0.0));
    });

    test(
      'calculates direction rotation clockwise from base direction (right)',
      () {
        const iconRight = DgIcon(
          'arrow_small',
          direction: DgIconDirection.right,
        );
        expect(iconRight.effectiveRotation, equals(0.0));

        const iconDown = DgIcon(
          'arrow_small',
          direction: DgIconDirection.down,
        );
        expect(
          iconDown.effectiveRotation,
          closeTo(math.pi / 2, 0.0001),
        ); // 90 degrees

        const iconLeft = DgIcon(
          'arrow_small',
          direction: DgIconDirection.left,
        );
        expect(
          iconLeft.effectiveRotation,
          closeTo(math.pi, 0.0001),
        ); // 180 degrees

        const iconUp = DgIcon('arrow_small', direction: DgIconDirection.up);
        expect(
          iconUp.effectiveRotation,
          closeTo(3 * math.pi / 2, 0.0001),
        ); // 270 degrees
      },
    );

    test('arrow_big rotation works for all directions', () {
      const iconDown = DgIcon('arrow_big', direction: DgIconDirection.down);
      expect(iconDown.effectiveRotation, closeTo(math.pi / 2, 0.0001));
    });

    test('static base direction registration works correctly', () {
      DgIcon.registerBaseDirection('chevron', DgIconDirection.up);

      const iconUp = DgIcon('chevron', direction: DgIconDirection.up);
      expect(iconUp.effectiveRotation, equals(0.0));

      const iconRight = DgIcon('chevron', direction: DgIconDirection.right);
      expect(iconRight.effectiveRotation, closeTo(math.pi / 2, 0.0001));
    });

    test('copyWith updates direction property correctly', () {
      const icon = DgIcon('arrow_small');
      final updated = icon.copyWith(direction: DgIconDirection.down);

      expect(updated.direction, equals(DgIconDirection.down));
      expect(updated.effectiveRotation, closeTo(math.pi / 2, 0.0001));
    });
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:candela_front/app/map/map_screen.dart';

void main() {
  group('candelaMapInteractions', () {
    final options = candelaMapInteractions();

    test('rotation by two-finger twist is disabled', () {
      expect(
        InteractiveFlag.hasFlag(options.flags, InteractiveFlag.rotate),
        isFalse,
      );
    });

    test('cursor/keyboard rotation is disabled too', () {
      // Ctrl+drag rotation is a separate option that defaults to enabled, so
      // clearing the rotate flag alone would still leave the map rotatable on
      // desktop and web.
      final isTrigger = options.cursorKeyboardRotationOptions.isKeyTrigger;
      expect(isTrigger, isNotNull, reason: 'rotation must be explicitly off');

      for (final key in CursorKeyboardRotationOptions.defaultTriggerKeys) {
        expect(
          isTrigger!(key),
          isFalse,
          reason: '$key must not rotate the map',
        );
      }
      expect(isTrigger!(LogicalKeyboardKey.shiftLeft), isFalse);
    });

    test('panning and zooming stay enabled', () {
      const expected = {
        'drag': InteractiveFlag.drag,
        'pinchMove': InteractiveFlag.pinchMove,
        'pinchZoom': InteractiveFlag.pinchZoom,
        'doubleTapZoom': InteractiveFlag.doubleTapZoom,
        'doubleTapDragZoom': InteractiveFlag.doubleTapDragZoom,
        'scrollWheelZoom': InteractiveFlag.scrollWheelZoom,
        'flingAnimation': InteractiveFlag.flingAnimation,
      };
      expected.forEach((name, flag) {
        expect(
          InteractiveFlag.hasFlag(options.flags, flag),
          isTrue,
          reason: '$name must remain available',
        );
      });
    });

    test('rotate is the only gesture removed from the full set', () {
      expect(options.flags, InteractiveFlag.all & ~InteractiveFlag.rotate);
    });
  });
}


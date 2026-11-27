import 'package:flutter/services.dart';

import 'model.dart';

String? bindingFromEvent(KeyEvent event) {
  final base =
      {
        LogicalKeyboardKey.arrowUp: 'UP',
        LogicalKeyboardKey.arrowDown: 'DOWN',
        LogicalKeyboardKey.arrowLeft: 'LEFT',
        LogicalKeyboardKey.arrowRight: 'RIGHT',
      }[event.logicalKey] ??
      event.logicalKey.keyLabel.toUpperCase();
  if (!safeKeys.contains(base)) return null;
  return withHeldModifiers(base);
}

String withHeldModifiers(String base) {
  final keyboard = HardwareKeyboard.instance;
  return '${keyboard.isControlPressed ? 'CTRL-' : ''}${keyboard.isAltPressed ? 'ALT-' : ''}${keyboard.isShiftPressed ? 'SHIFT-' : ''}$base';
}

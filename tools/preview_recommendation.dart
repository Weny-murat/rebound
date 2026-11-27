import 'dart:io';
import 'package:rebound/model.dart';

void main() {
  final p = Profile('Warlock · Destruction');
  p.movement.remove('MOVEBACKWARD');
  p.selectTalent(5, 108503);
  p.selectTalent(6, 196447);
  for (final a in p.active) {
    stdout.writeln('${p.bindings[a.id] ?? 'UNASSIGNED'}: ${a.name}');
  }
  stdout.writeln('Doomguard auto: ${p.bindings.containsKey(18540)}');
  stdout.writeln('S auto: ${p.bindings.containsValue('S')}');
}

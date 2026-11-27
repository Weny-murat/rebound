import 'dart:io';

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebound/main.dart';
import 'package:rebound/model.dart';

class TestFileSelector extends FileSelectorPlatform {
  String? openPath;
  String? savePath;
  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async => openPath == null ? null : XFile(openPath!);
  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) async => savePath == null ? null : FileSaveLocation(savePath!);
}

void main() {
  testWidgets(
    'Profile picker loads, saves as, reloads and keeps state on invalid file',
    (tester) async {
      final folder = Directory.systemTemp.createTempSync('rebound-test-');
      addTearDown(() => folder.deleteSync(recursive: true));
      final source = File('${folder.path}/source.json');
      final destination = File('${folder.path}/copy.json');
      final profile = Profile('Death Knight · Blood')
        ..keyboardLayout = 'en'
        ..keyboardAppearance = 'simple'
        ..mouseoverCombatRez = true;
      profile.suggest();
      source.writeAsStringSync(profile.toJson());
      final previous = FileSelectorPlatform.instance;
      final selector = TestFileSelector()
        ..openPath = source.path
        ..savePath = destination.path;
      FileSelectorPlatform.instance = selector;
      addTearDown(() => FileSelectorPlatform.instance = previous);
      await tester.pumpWidget(const ReboundApp());
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      Future<void> press(String label) async {
        await tester.runAsync(() async {
          await tester.tap(find.text(label));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
      }

      await press('Load profile');
      expect(find.text('Profile file: ${source.path}'), findsOneWidget);
      await press('Save as');
      expect(destination.existsSync(), isTrue);
      final saved = Profile.fromJson(destination.readAsStringSync());
      expect(saved.spec, profile.spec);
      expect(saved.bindings, profile.bindings);
      expect(saved.keyboardLayout, 'en');
      expect(saved.keyboardAppearance, 'simple');
      expect(saved.mouseoverCombatRez, isTrue);
      expect(saved.export(), contains('MACRO:61999='));
      expect(find.text('Profile file: ${destination.path}'), findsOneWidget);
      source.writeAsStringSync('{broken');
      await press('Load profile');
      expect(
        find.textContaining('The current layout was preserved.'),
        findsOneWidget,
      );
      expect(find.text('Profile file: ${destination.path}'), findsOneWidget);
      await press('Save profile');
      expect(
        Profile.fromJson(destination.readAsStringSync()).bindings,
        profile.bindings,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

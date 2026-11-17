import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moni/kanso/kanso_theme.dart';
import 'package:moni/kanso/kanso_tokens.dart';
import 'package:moni/kanso/kanso_widgets.dart';

void main() {
  test('Morning Matcha theme uses the light semantic roles', () {
    final theme = buildKansoTheme(KansoMode.morningMatcha);
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, KansoColors.morningMatcha.background);
    expect(theme.colorScheme.primary, KansoColors.morningMatcha.accentPrimary);
    expect(theme.colorScheme.surface, KansoColors.morningMatcha.surface);
    expect(theme.textTheme.headlineMedium?.fontSize, 22);
  });

  test('Evening Zen theme uses the dark semantic roles', () {
    final theme = buildKansoTheme(KansoMode.eveningZen);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, KansoColors.eveningZen.background);
    expect(theme.colorScheme.primary, KansoColors.eveningZen.accentPrimary);
    expect(theme.dividerTheme.color, KansoColors.eveningZen.borderSubtle);
    expect(theme.bottomSheetTheme.shape, isNotNull);
  });

  testWidgets('shared empty state renders without decoration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildKansoTheme(KansoMode.morningMatcha),
        home: const Scaffold(
          body: KansoEmptyState(
            icon: Icons.library_music_rounded,
            title: 'No music yet',
            message: 'Add a folder to begin.',
          ),
        ),
      ),
    );
    expect(find.text('No music yet'), findsOneWidget);
    expect(find.text('Add a folder to begin.'), findsOneWidget);
    expect(find.byIcon(Icons.library_music_rounded), findsOneWidget);
  });
}

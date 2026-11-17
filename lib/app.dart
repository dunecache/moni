import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/track.dart';
import 'kanso/kanso_theme.dart';
import 'kanso/kanso_tokens.dart';
import 'state/app_providers.dart';
import 'state/playback_controller.dart';
import 'ui/app_shell.dart';

class MoniApp extends ConsumerWidget {
  const MoniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'moni',
      debugShowCheckedModeBanner: false,
      theme: buildKansoTheme(KansoMode.morningMatcha),
      darkTheme: buildKansoTheme(KansoMode.eveningZen),
      themeMode: switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: const StartupGate(child: AppShell()),
    );
  }
}

/// Restores the saved playback queue from the previous session without
/// starting playback. Kept out of the shell so it runs exactly once.
class StartupGate extends ConsumerStatefulWidget {
  const StartupGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<StartupGate> {
  @override
  void initState() {
    super.initState();
    ref.read(themeModeProvider.notifier).state = ref.read(preferencesProvider).themeMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final library = ref.read(libraryProvider.notifier);
      ref.read(playbackProvider.notifier).restore(
            (paths) => paths.map(library.byPath).whereType<Track>().toList(),
          );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kanso/kanso_metrics.dart';
import '../../kanso/kanso_tokens.dart';
import '../../kanso/kanso_widgets.dart';
import '../../state/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.kanso;
    final text = Theme.of(context).textTheme;
    final library = ref.watch(libraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: KansoSpace.xxl),
        children: [
          KansoSectionHeader(title: 'Appearance'),
          const _ThemeModeTile(),
          const Divider(indent: KansoSpace.page, endIndent: KansoSpace.page),
          KansoSectionHeader(title: 'Local library'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KansoSpace.page, vertical: KansoSpace.sm),
            child: Text(
              'Add the folders that hold your audio files. Moni reads tags from the files themselves — nothing leaves your device.',
              style: text.bodySmall?.copyWith(color: k.textMuted),
            ),
          ),
          ...library.folders.map(
            (folder) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: KansoSpace.page),
              leading: Icon(Icons.folder_outlined, color: k.textSecondary, size: 20),
              title: Text(folder, style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: SizedBox(
                width: KansoSpace.touch,
                height: KansoSpace.touch,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Remove folder',
                  onPressed: () => ref.read(libraryProvider.notifier).removeFolder(folder),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KansoSpace.page, vertical: KansoSpace.sm),
            child: Row(
              children: [
                Expanded(
                  child: KansoPrimaryButton(
                    label: 'Add folder',
                    icon: Icons.add_rounded,
                    onPressed: () => _addFolder(context, ref),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KansoSpace.page, vertical: KansoSpace.sm),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: library.isScanning ? null : () => ref.read(libraryProvider.notifier).rescan(),
                    icon: library.isScanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(library.isScanning ? 'Scanning…' : 'Rescan library'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: k.textPrimary,
                      side: BorderSide(color: k.borderStrong),
                      minimumSize: const Size(0, KansoSpace.touch),
                      shape: const RoundedRectangleBorder(borderRadius: KansoRadius.medium),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (library.isScanning)
            LinearProgressIndicator(
              value: library.progress,
              color: k.accentPrimary,
              backgroundColor: k.surfaceSunken,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KansoSpace.page, vertical: KansoSpace.sm),
            child: Text('${library.tracks.length} songs indexed',
                style: text.bodySmall?.copyWith(color: k.textMuted)),
          ),
          const Divider(indent: KansoSpace.page, endIndent: KansoSpace.page),
          KansoSectionHeader(title: 'About'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KansoSpace.page),
            child: Text(
              'Moni is a local-first music player, designed with the Kanso Matcha visual language. '
              'Playback, artwork and metadata stay on your device.',
              style: text.bodySmall?.copyWith(color: k.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _addFolder(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a music folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '/path/to/your/music'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add')),
        ],
      ),
    );
    if (path == null || path.trim().isEmpty) return;
    await ref.read(libraryProvider.notifier).addFolder(path.trim());
  }
}

/// Theme mode is the only appearance setting: two Kanso modes, no accents to
/// configure. Dark Mode follows the system unless the user overrides it.
class _ThemeModeTile extends ConsumerWidget {
  const _ThemeModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.kanso;
    final current = ref.watch(themeModeProvider);
    return Column(
      children: [
        for (final entry in const <(String, String)>[
          ('system', 'Follow system'),
          ('light', 'Morning Matcha'),
          ('dark', 'Evening Zen'),
        ])
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: KansoSpace.page),
            title: Text(entry.$2, style: Theme.of(context).textTheme.bodyMedium),
            trailing: current == entry.$1
                ? Icon(Icons.check_rounded, color: k.accentStrong, size: 20)
                : null,
            onTap: () {
              ref.read(themeModeProvider.notifier).state = entry.$1;
              ref.read(preferencesProvider).setThemeMode(entry.$1);
            },
          ),
      ],
    );
  }
}

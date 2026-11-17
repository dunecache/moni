import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kanso/kanso_metrics.dart';
import '../../kanso/kanso_tokens.dart';
import '../../state/playback_controller.dart';
import 'kanso_artwork.dart';

/// The playback queue — not the library. Reordering and removal happen here.
class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.kanso;
    final text = Theme.of(context).textTheme;
    final playback = ref.watch(playbackProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(KansoSpace.page, KansoSpace.sm, KansoSpace.page, KansoSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: k.borderStrong, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: KansoSpace.md),
            Row(
              children: [
                Text('Up next', style: text.titleLarge),
                const Spacer(),
                Text('${playback.queue.length} songs', style: text.bodySmall?.copyWith(color: k.textMuted)),
              ],
            ),
            const SizedBox(height: KansoSpace.sm),
            Flexible(
              child: playback.queue.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(KansoSpace.xl),
                      child: Text(
                        'Nothing queued yet. Choose a song to begin.',
                        style: text.bodyMedium?.copyWith(color: k.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      itemCount: playback.queue.length,
                      onReorder: (from, to) => ref.read(playbackProvider.notifier).moveInQueue(from, to),
                      itemBuilder: (context, index) {
                        final track = playback.queue[index];
                        final isCurrent = index == playback.index;
                        return Container(
                          key: ValueKey<String>('${track.path}-$index'),
                          color: isCurrent ? k.selection : null,
                          child: ListTile(
                            leading: KansoArtwork(track: track, size: 44),
                            title: Text(
                              track.title,
                              style: text.titleSmall?.copyWith(
                                color: isCurrent ? k.accentStrong : k.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(track.artist,
                                style: text.bodySmall?.copyWith(color: k.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            trailing: SizedBox(
                              width: KansoSpace.touch,
                              height: KansoSpace.touch,
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                color: k.textMuted,
                                tooltip: 'Remove from queue',
                                onPressed: () => ref.read(playbackProvider.notifier).removeFromQueue(index),
                              ),
                            ),
                            onTap: () => ref.read(playbackProvider.notifier).jumpTo(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

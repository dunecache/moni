import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kanso/kanso_metrics.dart';
import '../../kanso/kanso_tokens.dart';
import '../../state/playback_controller.dart';
import 'kanso_artwork.dart';

/// A quiet, always-available bridge between browsing and listening.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, required this.onOpenPlayer});

  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final track = playback.current;
    if (track == null) return const SizedBox.shrink();

    final k = context.kanso;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: k.surface,
        border: Border(top: BorderSide(color: k.borderSubtle, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              value: playback.progress,
              backgroundColor: Colors.transparent,
              color: k.accentPrimary,
            ),
          ),
          InkWell(
            onTap: onOpenPlayer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: KansoSpace.page, vertical: KansoSpace.sm),
              child: Row(
                children: [
                  KansoArtwork(track: track, size: KansoArtworkSize.mini),
                  const SizedBox(width: KansoSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(track.title, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(track.artist, style: text.bodySmall?.copyWith(color: k.textMuted),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: KansoSpace.touch,
                    height: KansoSpace.touch,
                    child: IconButton(
                      icon: Icon(playback.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      color: k.textPrimary,
                      tooltip: playback.playing ? 'Pause' : 'Play',
                      onPressed: () => ref.read(playbackProvider.notifier).togglePlay(),
                    ),
                  ),
                  SizedBox(
                    width: KansoSpace.touch,
                    height: KansoSpace.touch,
                    child: IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      color: k.textSecondary,
                      tooltip: 'Next',
                      onPressed: () => ref.read(playbackProvider.notifier).skipNext(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

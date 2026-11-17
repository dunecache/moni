import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kanso/kanso_metrics.dart';
import '../../kanso/kanso_tokens.dart';
import '../../kanso/kanso_widgets.dart';
import '../../state/collection_controller.dart';
import '../../state/playback_controller.dart';
import '../widgets/kanso_artwork.dart';
import '../widgets/queue_sheet.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.kanso;
    final text = Theme.of(context).textTheme;
    final playback = ref.watch(playbackProvider);
    final collection = ref.watch(collectionProvider);
    final track = playback.current;
    final controller = ref.read(playbackProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Now playing', style: text.titleMedium),
        actions: [
          KansoIconButton(
            icon: Icons.queue_music_rounded,
            tooltip: 'Queue',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const QueueSheet(),
            ),
          ),
          const SizedBox(width: KansoSpace.xs),
        ],
      ),
      body: track == null
          ? const KansoEmptyState(
              icon: Icons.music_note_rounded,
              title: 'Nothing playing',
              message: 'Choose a song from your library to begin listening.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final artSize = constraints.maxWidth < 420
                    ? constraints.maxWidth - 80
                    : KansoArtworkSize.player;
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: KansoSpace.page),
                    child: Column(
                      children: [
                        const SizedBox(height: KansoSpace.lg),
                        KansoArtwork(
                          track: track,
                          embedded: true,
                          size: artSize.clamp(180.0, 320.0).toDouble(),
                          borderRadius: KansoRadius.large,
                        ),
                        const SizedBox(height: KansoSpace.xl),
                        Text(
                          track.title,
                          style: text.headlineMedium,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: KansoSpace.xs),
                        Text(
                          track.artist,
                          style: text.bodyLarge?.copyWith(color: k.textMuted),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (track.qualityLabel.isNotEmpty) ...[
                          const SizedBox(height: KansoSpace.xs),
                          Text(track.qualityLabel, style: text.labelSmall?.copyWith(color: k.textMuted)),
                        ],
                        const SizedBox(height: KansoSpace.xl),
                        _Progress(playback: playback),
                        const SizedBox(height: KansoSpace.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            KansoIconButton(
                              icon: playback.shuffle ? Icons.shuffle_rounded : Icons.shuffle_outlined,
                              tooltip: 'Shuffle',
                              selected: playback.shuffle,
                              onPressed: () => controller.setShuffle(!playback.shuffle),
                            ),
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: IconButton(
                                icon: const Icon(Icons.skip_previous_rounded, size: 32),
                                color: k.textPrimary,
                                tooltip: 'Previous',
                                onPressed: () => controller.skipPrevious(),
                              ),
                            ),
                            _PlayPauseButton(playing: playback.playing, onPressed: controller.togglePlay),
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: IconButton(
                                icon: const Icon(Icons.skip_next_rounded, size: 32),
                                color: k.textPrimary,
                                tooltip: 'Next',
                                onPressed: () => controller.skipNext(),
                              ),
                            ),
                            KansoIconButton(
                              icon: collection.isFavorite(track.path)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              tooltip: 'Love',
                              selected: collection.isFavorite(track.path),
                              onPressed: () => controller.toggleFavorite(),
                            ),
                          ],
                        ),
                        const SizedBox(height: KansoSpace.lg),
                        const SizedBox(height: KansoSpace.xxl),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.playing, required this.onPressed});

  final bool playing;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    return SizedBox(
      width: 76,
      height: 76,
      child: FilledButton(
        onPressed: () => onPressed(),
        style: FilledButton.styleFrom(
          backgroundColor: k.accentPrimary,
          foregroundColor: k.background,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 36),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.playback});

  final PlaybackStateData playback;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    final duration = playback.duration ?? Duration.zero;
    return Column(
      children: [
        Slider(
          value: playback.progress,
          onChanged: duration.inMilliseconds == 0
              ? null
              : (value) => refRead(context).seek(Duration(milliseconds: (duration.inMilliseconds * value).round())),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KansoSpace.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_format(playback.position), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: k.textMuted)),
              Text(_format(duration), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: k.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  static String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Small helper so the slider can reach the controller without turning the
/// whole progress bar into a ConsumerWidget.
PlaybackController refRead(BuildContext context) =>
    ProviderScope.containerOf(context).read(playbackProvider.notifier);

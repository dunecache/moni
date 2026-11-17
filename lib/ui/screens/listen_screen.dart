import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/track.dart';
import '../../kanso/kanso_metrics.dart';
import '../../kanso/kanso_tokens.dart';
import '../../kanso/kanso_widgets.dart';
import '../../state/app_providers.dart';
import '../../state/collection_controller.dart';
import '../../state/playback_controller.dart';
import '../widgets/album_card.dart';
import '../widgets/kanso_artwork.dart';
import '../widgets/track_tile.dart';

class ListenScreen extends ConsumerWidget {
  const ListenScreen({super.key, required this.onOpenSearch, required this.onOpenPlayer});

  final VoidCallback onOpenSearch;
  final VoidCallback onOpenPlayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k = context.kanso;
    final text = Theme.of(context).textTheme;
    final library = ref.watch(libraryProvider);
    final collection = ref.watch(collectionProvider);
    final playback = ref.watch(playbackProvider);
    final controller = ref.read(playbackProvider.notifier);

    final recents = collection.recentPaths
        .map((path) => ref.read(libraryProvider.notifier).byPath(path))
        .whereType<Track>()
        .take(6)
        .toList(growable: false);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(KansoSpace.page, KansoSpace.xl, KansoSpace.page, KansoSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(), style: text.headlineLarge),
                const SizedBox(height: KansoSpace.xs),
                Text('A quiet place for your music.', style: text.bodyMedium?.copyWith(color: k.textMuted)),
                const SizedBox(height: KansoSpace.lg),
                InkWell(
                  onTap: onOpenSearch,
                  borderRadius: KansoRadius.medium,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: k.surfaceSunken,
                      borderRadius: KansoRadius.medium,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: KansoSpace.md),
                        Icon(Icons.search_rounded, size: 20, color: k.textMuted),
                        const SizedBox(width: KansoSpace.sm),
                        Text('Search your library', style: text.bodyMedium?.copyWith(color: k.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (recents.isNotEmpty) ...[
          const SliverToBoxAdapter(child: KansoSectionHeader(title: 'Recently played')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 76,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: KansoSpace.page),
                scrollDirection: Axis.horizontal,
                itemCount: recents.length,
                separatorBuilder: (_, __) => const SizedBox(width: KansoSpace.md),
                itemBuilder: (context, index) {
                  final track = recents[index];
                  return GestureDetector(
                    onTap: () {
                      controller.playTrack(track, context: recents);
                      onOpenPlayer();
                    },
                    child: SizedBox(
                      width: 196,
                      child: Row(
                        children: [
                          KansoArtwork(track: track, size: 56),
                          const SizedBox(width: KansoSpace.sm),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(track.title, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(track.artist,
                                    style: text.bodySmall?.copyWith(color: k.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: KansoSectionHeader(title: 'Recently added')),
        if (library.tracks.isEmpty)
          const SliverToBoxAdapter(
            child: KansoEmptyState(
              icon: Icons.library_music_rounded,
              title: 'No music yet',
              message: 'Add a folder of local audio files in Settings to begin.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: KansoSpace.sm),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 148,
                mainAxisSpacing: KansoSpace.md,
                crossAxisSpacing: KansoSpace.sm,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final album = library.albums.isEmpty ? null : library.albums[index % library.albums.length];
                  if (album == null) return const SizedBox.shrink();
                  return AlbumCard(
                    album: album,
                    onTap: () => controller.playTracks(album.tracks, index: 0),
                  );
                },
                childCount: library.albums.take(8).length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: KansoSpace.xxl)),
      ],
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

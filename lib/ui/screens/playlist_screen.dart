import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/track.dart';
import '../../kanso/kanso_widgets.dart';
import '../../state/app_providers.dart';
import '../../state/collection_controller.dart';
import '../../state/playback_controller.dart';
import '../widgets/track_tile.dart';

class PlaylistScreen extends ConsumerWidget {
  const PlaylistScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(collectionProvider);
    final playback = ref.watch(playbackProvider);
    final isLoved = playlistId == '__loved__';
    final playlist = isLoved
        ? null
        : collection.playlists.where((p) => p.id == playlistId).cast<Playlist?>().firstOrNull;

    final paths = isLoved ? collection.favoritePaths.toList() : (playlist?.trackPaths ?? const <String>[]);
    final library = ref.read(libraryProvider.notifier);
    final tracks = paths.map(library.byPath).whereType<Track>().toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(isLoved ? 'Loved' : (playlist?.name ?? 'Playlist'))),
      body: tracks.isEmpty
          ? const KansoEmptyState(
              icon: Icons.playlist_play_rounded,
              title: 'Nothing here yet',
              message: 'Add songs from the library or the player to fill this collection.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      KansoPrimaryButton(
                        label: 'Play all',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () =>
                            ref.read(playbackProvider.notifier).playTracks(tracks, index: 0),
                      ),
                      const SizedBox(width: 8),
                      Text('${tracks.length} songs', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return TrackTile(
                        track: track,
                        isCurrent: playback.current?.path == track.path,
                        isFavorite: collection.favoritePaths.contains(track.path),
                        onTap: () => ref.read(playbackProvider.notifier).playTracks(tracks, index: index),
                        onFavorite: () =>
                            ref.read(collectionProvider.notifier).toggleFavorite(track.path),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

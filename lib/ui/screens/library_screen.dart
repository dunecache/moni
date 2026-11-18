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
import '../widgets/kanso_dialogs.dart';
import '../widgets/track_tile.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key, required this.onOpenSettings, required this.onOpenPlaylist});

  final VoidCallback onOpenSettings;
  final void Function(String playlistId) onOpenPlaylist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider);
    final collection = ref.watch(collectionProvider);
    final playback = ref.watch(playbackProvider);
    final controller = ref.read(playbackProvider.notifier);
    final k = context.kanso;
    final text = Theme.of(context).textTheme;

    final loved = collection.favoritePaths
        .map((path) => ref.read(libraryProvider.notifier).byPath(path))
        .whereType<Track>()
        .toList(growable: false);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          actions: [
            KansoIconButton(
              icon: Icons.tune_rounded,
              tooltip: 'Library folders',
              onPressed: library.tracks.isEmpty ? null : onOpenSettings,
            ),
          ],
          bottom: TabBar(
            labelColor: k.selectedInk,
            unselectedLabelColor: k.textMuted,
            indicatorColor:
                Theme.of(context).brightness == Brightness.dark ? k.accentPrimary : k.borderStrong,
            dividerColor: k.borderSubtle,
            labelStyle: text.labelMedium,
            tabs: const [
              Tab(text: 'Songs'),
              Tab(text: 'Albums'),
              Tab(text: 'Artists'),
              Tab(text: 'Playlists'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SongList(
              tracks: library.tracks,
              currentPath: playback.current?.path,
              favoritePaths: collection.favoritePaths.toSet(),
              onPlay: (track) => controller.playTrack(track, context: library.tracks),
              onFavorite: (track) => ref.read(collectionProvider.notifier).toggleFavorite(track.path),
              onOpenSettings: onOpenSettings,
            ),
            library.albums.isEmpty
                ? const KansoEmptyState(
                    icon: Icons.album_rounded,
                    title: 'No albums yet',
                    message: 'Albums appear here once your music has been scanned.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(KansoSpace.sm),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 148,
                      mainAxisSpacing: KansoSpace.md,
                      crossAxisSpacing: KansoSpace.sm,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: library.albums.length,
                    itemBuilder: (context, index) {
                      final album = library.albums[index];
                      return AlbumCard(
                        album: album,
                        onTap: () => controller.playTracks(album.tracks, index: 0),
                      );
                    },
                  ),
            library.artists.isEmpty
                ? const KansoEmptyState(
                    icon: Icons.person_outline_rounded,
                    title: 'No artists yet',
                    message: 'Artists are grouped from your local music tags.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: KansoSpace.page),
                    itemCount: library.artists.length,
                    itemBuilder: (context, index) {
                      final artist = library.artists[index];
                      return ArtistCard(
                        artist: artist,
                        onTap: () {
                          final tracks = artist.albums.expand((a) => a.tracks).toList();
                          if (tracks.isNotEmpty) controller.playTracks(tracks, index: 0);
                        },
                      );
                    },
                  ),
            _PlaylistsTab(
              playlists: collection.playlists,
              loved: loved,
              onOpenPlaylist: onOpenPlaylist,
              onCreate: (name) => ref.read(collectionProvider.notifier).createPlaylist(name),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongList extends StatelessWidget {
  const _SongList({
    required this.tracks,
    required this.currentPath,
    required this.favoritePaths,
    required this.onPlay,
    required this.onFavorite,
    required this.onOpenSettings,
  });

  final List<Track> tracks;
  final String? currentPath;
  final Set<String> favoritePaths;
  final void Function(Track track) onPlay;
  final void Function(Track track) onFavorite;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return KansoEmptyState(
        icon: Icons.library_music_rounded,
        title: 'Your library is empty',
        message: 'Add a folder of local audio files in Settings, then scan to build your library.',
        actionLabel: 'Add folder',
        onAction: onOpenSettings,
      );
    }
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return TrackTile(
          track: track,
          onTap: () => onPlay(track),
          isFavorite: favoritePaths.contains(track.path),
          isCurrent: currentPath == track.path,
          onFavorite: () => onFavorite(track),
        );
      },
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  const _PlaylistsTab({
    required this.playlists,
    required this.loved,
    required this.onOpenPlaylist,
    required this.onCreate,
  });

  final List<Playlist> playlists;
  final List<Track> loved;
  final void Function(String id) onOpenPlaylist;
  final void Function(String name) onCreate;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: KansoSpace.page),
      children: [
        const KansoSectionHeader(title: 'Collections', inset: false),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.favorite_rounded, color: k.accentStrong),
          title: Text('Loved', style: text.titleMedium),
          subtitle: Text('${loved.length} songs', style: text.bodySmall?.copyWith(color: k.textMuted)),
          onTap: () {
            // Loved is a virtual playlist; its id is a stable sentinel.
            onOpenPlaylist('__loved__');
          },
        ),
        const KansoSectionHeader(title: 'Your playlists', inset: false),
        ...playlists.map(
          (playlist) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.queue_music_rounded, color: k.textSecondary),
            title: Text(playlist.name, style: text.titleMedium),
            subtitle: Text('${playlist.trackPaths.length} songs',
                style: text.bodySmall?.copyWith(color: k.textMuted)),
            onTap: () => onOpenPlaylist(playlist.id),
          ),
        ),
        const SizedBox(height: KansoSpace.md),
        Align(
          alignment: Alignment.centerLeft,
          child: KansoPrimaryButton(
            label: 'New playlist',
            icon: Icons.add_rounded,
            onPressed: () => _showCreateDialog(context, onCreate),
          ),
        ),
        const SizedBox(height: KansoSpace.xxl),
      ],
    );
  }

  static Future<void> _showCreateDialog(
    BuildContext context,
    void Function(String name) onCreate,
  ) async {
    final name = await showKansoInputDialog(
      context: context,
      title: 'New playlist',
      hint: 'Playlist name',
      actionLabel: 'Create',
      helper: 'Playlists live only on this device.',
    );
    if (name != null) onCreate(name);
  }
}

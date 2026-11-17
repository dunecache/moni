import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../kanso/kanso_metrics.dart';
import '../../kanso/kanso_tokens.dart';
import '../../kanso/kanso_widgets.dart';
import '../../state/app_providers.dart';
import '../../state/collection_controller.dart';
import '../../state/playback_controller.dart';
import '../widgets/track_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.onOpenPlayer});

  final VoidCallback onOpenPlayer;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    final collection = ref.watch(collectionProvider);
    final playback = ref.watch(playbackProvider);
    final results = ref.read(libraryProvider.notifier).search(_query);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (value) => setState(() => _query = value),
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Songs, artists, albums',
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
      ),
      body: _query.trim().isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(KansoSpace.xl),
                child: Text(
                  'Search across your local library by title, artist, album or genre.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: k.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : results.isEmpty
              ? KansoEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches',
                  message: 'Nothing in your library matches “$_query”.',
                )
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final track = results[index];
                    return TrackTile(
                      track: track,
                      isFavorite: collection.favoritePaths.contains(track.path),
                      isCurrent: playback.current?.path == track.path,
                      onTap: () {
                        ref.read(playbackProvider.notifier).playTrack(track, context: results);
                        widget.onOpenPlayer();
                      },
                      onFavorite: () => ref.read(collectionProvider.notifier).toggleFavorite(track.path),
                    );
                  },
                ),
    );
  }
}

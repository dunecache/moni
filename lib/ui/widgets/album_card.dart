import 'package:flutter/material.dart';

import '../../data/library_repository.dart';
import '../../data/track.dart';
import '../../kanso/kanso_metrics.dart';
import '../../kanso/kanso_tokens.dart';
import 'kanso_artwork.dart';

class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.album, required this.onTap});

  final Album album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    final text = Theme.of(context).textTheme;
    final cover = album.tracks.isEmpty ? null : album.tracks.first;

    return InkWell(
      onTap: onTap,
      borderRadius: KansoRadius.medium,
      child: Padding(
        padding: const EdgeInsets.all(KansoSpace.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KansoArtwork(
              track: cover,
              size: KansoArtworkSize.card,
              borderRadius: KansoRadius.medium,
            ),
            const SizedBox(height: KansoSpace.sm),
            Text(
              album.name,
              style: text.titleSmall?.copyWith(color: k.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              album.artist,
              style: text.bodySmall?.copyWith(color: k.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class ArtistCard extends StatelessWidget {
  const ArtistCard({super.key, required this.artist, required this.onTap});

  final ArtistInfo artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    final text = Theme.of(context).textTheme;
    final cover = artist.albums.isEmpty || artist.albums.first.tracks.isEmpty
        ? null
        : artist.albums.first.tracks.first;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KansoSpace.sm),
        child: Row(
          children: [
            KansoArtwork(
              track: cover,
              size: 56,
              borderRadius: const BorderRadius.all(Radius.circular(28)),
            ),
            const SizedBox(width: KansoSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(artist.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${artist.albums.length} albums · ${artist.trackCount} songs',
                    style: text.bodySmall?.copyWith(color: k.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../data/track.dart';
import '../../kanso/kanso_metrics.dart';
import '../../kanso/kanso_tokens.dart';
import 'kanso_artwork.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onFavorite,
    this.onMore,
    this.isFavorite = false,
    this.isCurrent = false,
    this.subtitle,
    this.trailing,
  });

  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onMore;
  final bool isFavorite;
  final bool isCurrent;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    final text = Theme.of(context).textTheme;
    final titleStyle = (text.titleMedium ?? const TextStyle()).copyWith(
      color: isCurrent ? k.accentStrong : k.textPrimary,
      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isCurrent ? k.selection : null,
        padding: const EdgeInsets.symmetric(horizontal: KansoSpace.page, vertical: KansoSpace.sm),
        child: Row(
          children: [
            KansoArtwork(track: track),
            const SizedBox(width: KansoSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? '${track.artist} · ${track.album}',
                    style: text.bodySmall?.copyWith(color: k.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onFavorite != null)
              SizedBox(
                width: KansoSpace.touch,
                height: KansoSpace.touch,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                  ),
                  color: isFavorite ? k.accentStrong : k.textMuted,
                  tooltip: isFavorite ? 'Remove from loved' : 'Love',
                  onPressed: onFavorite,
                ),
              ),
            if (onMore != null)
              SizedBox(
                width: KansoSpace.touch,
                height: KansoSpace.touch,
                child: IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, size: 20),
                  color: k.textMuted,
                  tooltip: 'More',
                  onPressed: onMore,
                ),
              ),
            const SizedBox(width: KansoSpace.sm),
            Text(
              track.durationLabel,
              style: text.labelSmall?.copyWith(color: k.textMuted, fontFeatures: const <FontFeature>[]),
            ),
          ],
        ),
      ),
    );
  }
}

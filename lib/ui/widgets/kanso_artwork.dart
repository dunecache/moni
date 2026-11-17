import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../data/track.dart';
import '../../kanso/kanso_metrics.dart';
import '../../kanso/kanso_tokens.dart';
import '../../playback/artwork.dart';

final Map<String, Uint8List?> _embeddedCache = <String, Uint8List?>{};

/// Artwork with a calm fallback. Prefers a sibling cover file, then embedded
/// art (read once per track), then a quiet tonal placeholder.
class KansoArtwork extends StatelessWidget {
  const KansoArtwork({
    super.key,
    required this.track,
    this.size = KansoArtworkSize.row,
    this.borderRadius = KansoRadius.small,
    this.embedded = false,
  });

  final Track? track;
  final double size;
  final BorderRadius borderRadius;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: k.surfaceSunken, borderRadius: borderRadius),
      child: Icon(Icons.album_rounded, size: size * 0.36, color: k.accentSecondary),
    );

    if (track == null) return placeholder;

    final path = track!.coverPath;
    if (!embedded && path != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder,
        ),
      );
    }

    if (_embeddedCache.containsKey(track!.path)) {
      final cached = _embeddedCache[track!.path];
      if (cached == null) return placeholder;
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.memory(cached, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder),
      );
    }

    return FutureBuilder<Uint8List?>(
      future: readEmbeddedArtwork(track!.path),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return placeholder;
        final bytes = snapshot.data;
        _embeddedCache[track!.path] = bytes;
        if (bytes == null) return placeholder;
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder),
        );
      },
    );
  }
}

abstract final class KansoArtworkSize {
  static const double mini = 44;
  static const double row = 56;
  static const double card = 132;
  static const double player = 280;
}

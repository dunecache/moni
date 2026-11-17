import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

/// Reads embedded cover art for one file, on demand.
///
/// Scanning deliberately skips images; only the artwork actually on screen is
/// decoded. This keeps a large local library fast to open.
Future<Uint8List?> readEmbeddedArtwork(String path) async {
  try {
    final metadata = readMetadata(File(path), getImage: true);
    if (metadata.pictures.isEmpty) return null;
    return metadata.pictures.first.bytes;
  } catch (_) {
    return null;
  }
}

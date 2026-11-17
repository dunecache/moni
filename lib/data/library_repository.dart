import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart' show compute, immutable;

import 'track.dart';

/// An album grouping derived from track tags.
@immutable
class Album {
  const Album({
    required this.name,
    required this.artist,
    required this.tracks,
    this.coverPath,
    this.year,
  });

  final String name;
  final String artist;
  final List<Track> tracks;
  final String? coverPath;
  final DateTime? year;

  String get id => '$artist\u0000$name';
}

/// An artist grouping derived from `albumArtist` (falling back to `artist`).
@immutable
class ArtistInfo {
  const ArtistInfo({required this.name, required this.albums});

  final String name;
  final List<Album> albums;

  int get trackCount => albums.fold<int>(0, (sum, album) => sum + album.tracks.length);
}

/// In-memory index of the user's local music, persisted as a lightweight cache.
class LibraryRepository {
  final List<Track> _tracks = <Track>[];
  final List<Album> _albums = <Album>[];
  final List<ArtistInfo> _artists = <ArtistInfo>[];

  List<Track> get tracks => List<Track>.unmodifiable(_tracks);
  List<Album> get albums => List<Album>.unmodifiable(_albums);
  List<ArtistInfo> get artists => List<ArtistInfo>.unmodifiable(_artists);
  bool get isEmpty => _tracks.isEmpty;

  void replaceAll(List<Track> tracks) {
    _tracks
      ..clear()
      ..addAll(tracks);
    _rebuildIndexes();
  }

  void add(Track track) {
    if (_tracks.contains(track)) return;
    _tracks.add(track);
    _rebuildIndexes();
  }

  Track? byPath(String path) {
    for (final track in _tracks) {
      if (track.path == path) return track;
    }
    return null;
  }

  List<Track> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return tracks;
    return _tracks.where((t) {
      return t.title.toLowerCase().contains(q) ||
          t.artist.toLowerCase().contains(q) ||
          t.album.toLowerCase().contains(q) ||
          t.albumArtist?.toLowerCase().contains(q) == true ||
          t.genres.any((g) => g.toLowerCase().contains(q));
    }).toList(growable: false);
  }

  List<Track> forAlbum(String id) =>
      _albums.where((a) => a.id == id).expand((a) => a.tracks).toList(growable: false);

  List<Track> forArtist(String name) => _tracks
      .where((t) => t.albumCredit == name || t.artist == name)
      .toList(growable: false);

  List<Track> recentlyAdded({int limit = 12}) {
    final sorted = List<Track>.from(_tracks)..sort((a, b) {
        final aTime = _modified(a.path);
        final bTime = _modified(b.path);
        return bTime.compareTo(aTime);
      });
    return sorted.take(limit).toList(growable: false);
  }

  /// Scans the given roots recursively, reading tags off the UI isolate.
  /// Existing cache entries for removed files are dropped.
  Future<List<Track>> scan(
    List<String> roots, {
    void Function(int done, int total)? onProgress,
  }) async {
    final files = <File>[];
    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File && _isAudio(entity.path)) files.add(entity);
        }
      } on FileSystemException {
        // An inaccessible subfolder should not abort the whole scan.
        continue;
      }
    }

    final found = <Track>[];
    var done = 0;
    for (final file in files) {
      final track = await compute<_ReadArgs, Track?>(_readTrack, _ReadArgs(file.path));
      if (track != null) found.add(track);
      done++;
      onProgress?.call(done, files.length);
    }

    found.sort((a, b) => a.path.compareTo(b.path));
    replaceAll(found);
    return tracks;
  }

  void _rebuildIndexes() {
    _albums.clear();
    _artists.clear();

    final grouped = <String, List<Track>>{};
    for (final track in _tracks) {
      grouped.putIfAbsent(_albumKey(track), () => <Track>[]).add(track);
    }
    for (final entry in grouped.entries) {
      final sorted = List<Track>.from(entry.value)..sort((a, b) {
          final disc = (a.discNumber ?? 1).compareTo(b.discNumber ?? 1);
          if (disc != 0) return disc;
          final number = (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
          if (number != 0) return number;
          return a.title.compareTo(b.title);
        });
      _albums.add(Album(
        name: sorted.first.album,
        artist: sorted.first.albumCredit,
        tracks: List<Track>.unmodifiable(sorted),
        coverPath: sorted.first.coverPath,
        year: sorted.first.year,
      ));
    }
    _albums.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));

    final byArtist = <String, List<Album>>{};
    for (final album in _albums) {
      byArtist.putIfAbsent(album.artist, () => <Album>[]).add(album);
    }
    for (final entry in byArtist.entries) {
      _artists.add(ArtistInfo(name: entry.key, albums: List<Album>.unmodifiable(entry.value)));
    }
    _artists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  static String _albumKey(Track track) => '${track.albumCredit}\u0000${track.album}';

  static bool _isAudio(String path) {
    final lower = path.toLowerCase();
    return supportedFileExtensions.any(lower.endsWith);
  }

  static DateTime _modified(String path) {
    try {
      return File(path).lastModifiedSync();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

class _ReadArgs {
  const _ReadArgs(this.path);
  final String path;
}

Track? _readTrack(_ReadArgs args) => Track.fromFile(
      File(args.path),
      coverPath: _findSiblingCover(args.path),
    );

/// Prefers artwork that sits beside the audio file — no network, no guessing.
String? _findSiblingCover(String audioPath) {
  final dir = File(audioPath).parent.path;
  const names = <String>[
    'cover.jpg',
    'cover.jpeg',
    'cover.png',
    'folder.jpg',
    'folder.png',
    'album.jpg',
    'front.jpg',
  ];
  for (final name in names) {
    final candidate = File('$dir${Platform.pathSeparator}$name');
    if (candidate.existsSync()) return candidate.path;
  }
  return null;
}

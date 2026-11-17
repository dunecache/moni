import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart' show immutable;

/// A local audio file and its cached display metadata.
///
/// The file path is the identity: the same file can never appear twice in the
/// library, and playlists/recent lists store only paths.
@immutable
class Track {
  const Track({
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist,
    this.trackNumber,
    this.discNumber,
    this.duration,
    this.year,
    this.lyrics,
    this.coverPath,
    this.genres = const <String>[],
  });

  final String path;
  final String title;
  final String artist;
  final String album;
  final String? albumArtist;
  final int? trackNumber;
  final int? discNumber;
  final Duration? duration;
  final DateTime? year;
  final String? lyrics;
  final String? coverPath;
  final List<String> genres;

  String get id => path;

  String get fileName => path.split(Platform.pathSeparator).last;

  String get albumCredit => (albumArtist ?? artist).trim().isEmpty ? 'Unknown artist' : (albumArtist ?? artist);

  String get durationLabel {
    final d = duration;
    if (d == null) return '--:--';
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get qualityLabel {
    final parts = <String>[];
    if (year != null) parts.add(year!.year.toString());
    if (genres.isNotEmpty) parts.add(genres.first);
    return parts.join(' · ');
  }

  /// Reads the tags of a real file. Covers are intentionally not read here —
  /// embedded artwork is loaded on demand for the player only.
  static Track? fromFile(File file, {String? coverPath}) {
    AudioMetadata metadata;
    try {
      metadata = readMetadata(file, getImage: false);
    } catch (_) {
      return null;
    }
    final fallback = parseFileName(file.path);
    final title = _clean(metadata.title) ?? fallback.$1;
    final artist = _clean(metadata.artist) ?? fallback.$2;
    final album = _clean(metadata.album) ?? 'Unknown album';
    return Track(
      path: file.path,
      title: title,
      artist: artist,
      album: album,
      albumArtist: _clean(metadata.albumArtist),
      trackNumber: metadata.trackNumber,
      discNumber: metadata.discNumber,
      duration: metadata.duration,
      year: metadata.year,
      lyrics: metadata.lyrics,
      coverPath: coverPath,
      genres: List<String>.unmodifiable(metadata.genres),
    );
  }

  /// Best-effort title/artist extraction from `NN - Artist - Title.ext`.
  static (String, String) parseFileName(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final withoutExt = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
    final parts = withoutExt.split(RegExp(r'\s+[-–—]\s+'));
    if (parts.length >= 3) return (parts.sublist(2).join(' - '), parts[1]);
    if (parts.length == 2) return (parts[1], parts[0]);
    return (withoutExt, 'Unknown artist');
  }

  static String? _clean(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'unknown') return null;
    return trimmed;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'path': path,
        'title': title,
        'artist': artist,
        'album': album,
        'albumArtist': albumArtist,
        'trackNumber': trackNumber,
        'discNumber': discNumber,
        'durationMs': duration?.inMilliseconds,
        'year': year?.year,
        'lyrics': lyrics,
        'coverPath': coverPath,
        'genres': genres,
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        path: json['path'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        album: json['album'] as String,
        albumArtist: json['albumArtist'] as String?,
        trackNumber: json['trackNumber'] as int?,
        discNumber: json['discNumber'] as int?,
        duration: json['durationMs'] == null ? null : Duration(milliseconds: json['durationMs'] as int),
        year: json['year'] == null ? null : DateTime(json['year'] as int),
        lyrics: json['lyrics'] as String?,
        coverPath: json['coverPath'] as String?,
        genres: (json['genres'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
      );

  @override
  bool operator ==(Object other) => other is Track && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

/// A user-made, ordered collection of local tracks.
@immutable
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.trackPaths,
    required this.createdAt,
  });

  final String id;
  final String name;
  final List<String> trackPaths;
  final DateTime createdAt;

  Playlist copyWith({String? name, List<String>? trackPaths}) => Playlist(
        id: id,
        name: name ?? this.name,
        trackPaths: trackPaths ?? this.trackPaths,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'trackPaths': trackPaths,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
        id: json['id'] as String,
        name: json['name'] as String,
        trackPaths: (json['trackPaths'] as List<dynamic>).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

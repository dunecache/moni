import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'track.dart';

/// All durable user state for the local player.
///
/// Kept small and explicit: a handful of JSON blobs rather than a database.
/// The library cache is rebuilt from files on demand; everything else is
/// user-authored and must never be silently discarded.
class MoniPreferences {
  MoniPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _themeMode = 'theme_mode';
  static const _folders = 'library_folders';
  static const _libraryCache = 'library_cache_v1';
  static const _favorites = 'favorites_v1';
  static const _playlists = 'playlists_v1';
  static const _recents = 'recent_tracks_v1';
  static const _queuePaths = 'playback_queue_v1';
  static const _queueIndex = 'playback_index_v1';
  static const _queuePosition = 'playback_position_v1';
  static const _shuffle = 'playback_shuffle_v1';

  Future<void> init() async => _prefs.reload();

  // Theme -----------------------------------------------------------------
  String get themeMode => _prefs.getString(_themeMode) ?? 'system';
  Future<void> setThemeMode(String value) => _prefs.setString(_themeMode, value);

  // Library folders --------------------------------------------------------
  List<String> get folders => _prefs.getStringList(_folders) ?? const <String>[];
  Future<void> setFolders(List<String> value) => _prefs.setStringList(_folders, value);

  // Library cache ----------------------------------------------------------
  List<Track> readLibraryCache() {
    final raw = _prefs.getString(_libraryCache);
    if (raw == null || raw.isEmpty) return const <Track>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Track.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <Track>[];
    }
  }

  Future<void> writeLibraryCache(List<Track> tracks) =>
      _prefs.setString(_libraryCache, jsonEncode(tracks.map((t) => t.toJson()).toList()));

  // Favorites --------------------------------------------------------------
  List<String> get favoritePaths => _prefs.getStringList(_favorites) ?? const <String>[];
  Future<void> setFavoritePaths(List<String> value) => _prefs.setStringList(_favorites, value);

  // Playlists --------------------------------------------------------------
  List<Playlist> readPlaylists() {
    final raw = _prefs.getString(_playlists);
    if (raw == null || raw.isEmpty) return const <Playlist>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Playlist.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <Playlist>[];
    }
  }

  Future<void> writePlaylists(List<Playlist> playlists) =>
      _prefs.setString(_playlists, jsonEncode(playlists.map((p) => p.toJson()).toList()));

  // Recents ----------------------------------------------------------------
  List<String> get recentPaths => _prefs.getStringList(_recents) ?? const <String>[];
  Future<void> setRecentPaths(List<String> value) => _prefs.setStringList(_recents, value);

  /// Records a play, keeping the list bounded and most-recent-first.
  Future<void> recordPlay(String path) async {
    final updated = <String>[path, ...recentPaths.where((p) => p != path)].take(50).toList();
    await setRecentPaths(updated);
  }

  // Playback snapshot ------------------------------------------------------
  List<String> get queuePaths => _prefs.getStringList(_queuePaths) ?? const <String>[];
  int get queueIndex => _prefs.getInt(_queueIndex) ?? 0;
  int get queuePositionMs => _prefs.getInt(_queuePosition) ?? 0;
  bool get shuffle => _prefs.getBool(_shuffle) ?? false;

  Future<void> savePlaybackSnapshot({
    required List<String> paths,
    required int index,
    required int positionMs,
    required bool shuffle,
  }) async {
    await _prefs.setStringList(_queuePaths, paths);
    await _prefs.setInt(_queueIndex, index);
    await _prefs.setInt(_queuePosition, positionMs);
    await _prefs.setBool(_shuffle, shuffle);
  }
}

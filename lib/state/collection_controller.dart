import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preferences.dart';
import '../data/track.dart';
import 'app_providers.dart';

@immutable
class CollectionState {
  const CollectionState({
    this.favorites = const <String>{},
    this.playlists = const <Playlist>[],
    this.recentPaths = const <String>[],
  });

  final Set<String> favorites;
  final List<Playlist> playlists;
  final List<String> recentPaths;

  List<String> get favoritePaths => favorites.toList(growable: false);

  bool isFavorite(String path) => favorites.contains(path);

  CollectionState copyWith({
    Set<String>? favorites,
    List<Playlist>? playlists,
    List<String>? recentPaths,
  }) =>
      CollectionState(
        favorites: favorites ?? this.favorites,
        playlists: playlists ?? this.playlists,
        recentPaths: recentPaths ?? this.recentPaths,
      );
}

final collectionProvider =
    StateNotifierProvider<CollectionController, CollectionState>((ref) {
  return CollectionController(ref.read(preferencesProvider));
});

class CollectionController extends StateNotifier<CollectionState> {
  CollectionController(this._prefs)
      : super(CollectionState(
          favorites: _prefs.favoritePaths.toSet(),
          playlists: _prefs.readPlaylists(),
          recentPaths: _prefs.recentPaths,
        ));

  final MoniPreferences _prefs;

  bool isFavorite(String path) => state.favorites.contains(path);

  Future<void> toggleFavorite(String path) async {
    final next = state.favorites.toSet();
    if (!next.add(path)) next.remove(path);
    await _prefs.setFavoritePaths(next.toList());
    state = state.copyWith(favorites: next);
  }

  Future<void> recordPlay(String path) async {
    await _prefs.recordPlay(path);
    state = state.copyWith(recentPaths: _prefs.recentPaths);
  }

  Future<void> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      trackPaths: const <String>[],
      createdAt: DateTime.now(),
    );
    final next = <Playlist>[...state.playlists, playlist];
    await _persistPlaylists(next);
  }

  Future<void> renamePlaylist(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final next = state.playlists
        .map((p) => p.id == id ? p.copyWith(name: trimmed) : p)
        .toList();
    await _persistPlaylists(next);
  }

  Future<void> deletePlaylist(String id) async {
    final next = state.playlists.where((p) => p.id != id).toList();
    await _persistPlaylists(next);
  }

  Future<void> addToPlaylist(String id, String trackPath) async {
    final next = state.playlists.map((p) {
      if (p.id != id || p.trackPaths.contains(trackPath)) return p;
      return p.copyWith(trackPaths: <String>[...p.trackPaths, trackPath]);
    }).toList();
    await _persistPlaylists(next);
  }

  Future<void> removeFromPlaylist(String id, String trackPath) async {
    final next = state.playlists.map((p) {
      if (p.id != id) return p;
      return p.copyWith(trackPaths: p.trackPaths.where((path) => path != trackPath).toList());
    }).toList();
    await _persistPlaylists(next);
  }

  Future<void> _persistPlaylists(List<Playlist> next) async {
    await _prefs.writePlaylists(next);
    state = state.copyWith(playlists: next);
  }
}

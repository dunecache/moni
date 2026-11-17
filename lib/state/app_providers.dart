import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/library_repository.dart';
import '../data/preferences.dart';
import '../data/track.dart';
import '../playback/moni_audio_handler.dart';

/// Provided by `main()` after SharedPreferences and audio_service initialize.
final preferencesProvider = Provider<MoniPreferences>((ref) {
  throw UnimplementedError('preferencesProvider must be overridden in main()');
});

final audioHandlerProvider = Provider<MoniAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main()');
});

/// One of `system`, `light` (Morning Matcha) or `dark` (Evening Zen).
final themeModeProvider = StateProvider<String>((ref) => 'system');

@immutable
class LibraryState {
  const LibraryState({
    this.tracks = const <Track>[],
    this.albums = const <Album>[],
    this.artists = const <ArtistInfo>[],
    this.folders = const <String>[],
    this.isScanning = false,
    this.progress = 0,
  });

  final List<Track> tracks;
  final List<Album> albums;
  final List<ArtistInfo> artists;
  final List<String> folders;
  final bool isScanning;
  final double progress;

  LibraryState copyWith({
    List<Track>? tracks,
    List<Album>? albums,
    List<ArtistInfo>? artists,
    List<String>? folders,
    bool? isScanning,
    double? progress,
  }) =>
      LibraryState(
        tracks: tracks ?? this.tracks,
        albums: albums ?? this.albums,
        artists: artists ?? this.artists,
        folders: folders ?? this.folders,
        isScanning: isScanning ?? this.isScanning,
        progress: progress ?? this.progress,
      );
}

final libraryProvider = StateNotifierProvider<LibraryController, LibraryState>((ref) {
  return LibraryController(ref.read(preferencesProvider));
});

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController(this._prefs) : super(const LibraryState()) {
    _repo.replaceAll(_prefs.readLibraryCache());
    _publish();
  }

  final MoniPreferences _prefs;
  final LibraryRepository _repo = LibraryRepository();

  LibraryRepository get repository => _repo;

  Track? byPath(String path) => _repo.byPath(path);
  List<Track> forAlbum(String id) => _repo.forAlbum(id);
  List<Track> forArtist(String name) => _repo.forArtist(name);
  List<Track> search(String query) => _repo.search(query);
  List<Track> recentlyAdded({int limit = 12}) => _repo.recentlyAdded(limit: limit);

  void _publish() {
    state = state.copyWith(
      tracks: _repo.tracks,
      albums: _repo.albums,
      artists: _repo.artists,
      folders: _prefs.folders,
    );
  }

  Future<void> rescan() async {
    if (state.isScanning) return;
    state = state.copyWith(isScanning: true, progress: 0);
    try {
      final tracks = await _repo.scan(
        _prefs.folders,
        onProgress: (done, total) {
          state = state.copyWith(progress: total == 0 ? 1 : done / total);
        },
      );
      await _prefs.writeLibraryCache(tracks);
    } finally {
      state = state.copyWith(isScanning: false, progress: 1);
      _publish();
    }
  }

  Future<void> addFolder(String path) async {
    final folders = {..._prefs.folders, path}.toList()..sort();
    await _prefs.setFolders(folders);
    _publish();
    await rescan();
  }

  Future<void> removeFolder(String path) async {
    final folders = _prefs.folders.where((f) => f != path).toList();
    await _prefs.setFolders(folders);
    await rescan();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/preferences.dart';
import '../data/track.dart';
import '../playback/moni_audio_handler.dart';
import 'app_providers.dart';
import 'collection_controller.dart';

@immutable
class PlaybackStateData {
  const PlaybackStateData({
    this.current,
    this.queue = const <Track>[],
    this.index = 0,
    this.playing = false,
    this.shuffle = false,
    this.position = Duration.zero,
    this.duration,
    this.loading = false,
  });

  final Track? current;
  final List<Track> queue;
  final int index;
  final bool playing;
  final bool shuffle;
  final Duration position;
  final Duration? duration;
  final bool loading;

  double get progress {
    final total = duration?.inMilliseconds ?? 0;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  PlaybackStateData copyWith({
    Track? current,
    List<Track>? queue,
    int? index,
    bool? playing,
    bool? shuffle,
    Duration? position,
    Duration? duration,
    bool? loading,
  }) =>
      PlaybackStateData(
        current: current ?? this.current,
        queue: queue ?? this.queue,
        index: index ?? this.index,
        playing: playing ?? this.playing,
        shuffle: shuffle ?? this.shuffle,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        loading: loading ?? this.loading,
      );
}

final playbackProvider =
    StateNotifierProvider<PlaybackController, PlaybackStateData>((ref) {
  return PlaybackController(
    ref.read(audioHandlerProvider),
    ref.read(preferencesProvider),
    ref.read(collectionProvider.notifier),
  );
});

class PlaybackController extends StateNotifier<PlaybackStateData> {
  PlaybackController(this._handler, this._prefs, this._collection)
      : super(const PlaybackStateData()) {
    _handler.onTrackChanged = (track) {
      state = state.copyWith(current: track);
      if (track != null) _collection.recordPlay(track.path);
    };
    _handler.onQueueChanged = (queue, index) =>
        state = state.copyWith(queue: queue, index: index);
    _handler.onPositionSaved = (index, position) => _saveSnapshot(index, position);

    _subscriptions = <StreamSubscription<dynamic>>[
      _handler.positionStream.listen((p) => state = state.copyWith(position: p)),
      _handler.durationStream.listen((d) => state = state.copyWith(duration: d)),
      _handler.playingStream.listen((p) => state = state.copyWith(playing: p)),
      _handler.processingStateStream.listen((s) =>
          state = state.copyWith(loading: s == ProcessingState.loading || s == ProcessingState.buffering)),
    ];
    _snapshotTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (state.playing) _saveSnapshot(state.index, state.position);
    });
  }

  final MoniAudioHandler _handler;
  final MoniPreferences _prefs;
  final CollectionController _collection;
  late final List<StreamSubscription<dynamic>> _subscriptions;
  Timer? _snapshotTimer;

  Future<void> playTracks(List<Track> tracks, {required int index}) async {
    if (tracks.isEmpty) return;
    await _handler.setQueue(tracks, index: index, shuffle: false);
    if (state.shuffle) await _handler.setShuffle(true);
    await _handler.play();
  }

  Future<void> playTrack(Track track, {List<Track>? context}) async {
    final tracks = context ?? <Track>[track];
    final index = tracks.indexWhere((t) => t.path == track.path);
    await playTracks(tracks, index: index < 0 ? 0 : index);
  }

  Future<void> togglePlay() async {
    final handler = _handler;
    if (handler.playing) {
      await handler.pause();
    } else {
      await handler.play();
    }
  }

  Future<void> skipNext() => _handler.skipToNext();
  Future<void> skipPrevious() => _handler.skipToPrevious();
  Future<void> seek(Duration position) => _handler.seek(position);
  Future<void> jumpTo(int index) => _handler.jumpTo(index);
  Future<void> insertNext(Track track) => _handler.insertNext(track);
  Future<void> removeFromQueue(int index) => _handler.removeAt(index);
  Future<void> moveInQueue(int from, int to) => _handler.move(from, to);

  Future<void> setShuffle(bool enabled) async {
    await _handler.setShuffle(enabled);
    state = state.copyWith(shuffle: enabled);
    await _saveSnapshot(state.index, state.position);
  }

  Future<void> toggleFavorite() async {
    final path = state.current?.path;
    if (path != null) await _collection.toggleFavorite(path);
  }

  /// Loads the saved queue and position without starting playback.
  Future<void> restore(List<Track> Function(List<String> paths) resolver) async {
    final tracks = resolver(_prefs.queuePaths).toList(growable: false);
    if (tracks.isEmpty) return;
    await _handler.restoreQueue(
      tracks,
      index: _prefs.queueIndex,
      position: Duration(milliseconds: _prefs.queuePositionMs),
    );
    await _handler.setShuffle(_prefs.shuffle);
    state = state.copyWith(shuffle: _prefs.shuffle);
  }

  void _saveSnapshot(int index, Duration position) {
    _prefs.savePlaybackSnapshot(
      paths: state.queue.map((t) => t.path).toList(),
      index: index,
      positionMs: position.inMilliseconds,
      shuffle: state.shuffle,
    );
  }

  @override
  void dispose() {
    _snapshotTimer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

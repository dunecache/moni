import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../data/track.dart';

/// The single playback core for the app.
///
/// UI never talks to [AudioPlayer] directly. It calls this handler, which owns
/// the queue, publishes the OS media session, and keeps the notification and
/// lock-screen controls in sync with the in-app player.
class MoniAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  MoniAudioHandler({
    AudioPlayer? player,
    this.onTrackChanged,
    this.onQueueChanged,
    this.onPositionSaved,
  }) : _player = player ?? AudioPlayer() {
    _player.playbackEventStream.listen(_onPlaybackEvent, onError: (_) {});
    _player.currentIndexStream.listen(_onCurrentIndex, onError: (_) {});
    _positionTicker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_player.playing) _publishState();
    });
  }

  final AudioPlayer _player;
  Timer? _positionTicker;

  final void Function(Track? track)? onTrackChanged;
  final void Function(List<Track> queue, int index)? onQueueChanged;
  final void Function(int index, Duration position)? onPositionSaved;

  final List<Track> _queue = <Track>[];
  final List<Track> _originalQueue = <Track>[];
  int _index = 0;
  bool _shuffle = false;

  List<Track> get queue => List<Track>.unmodifiable(_queue);
  int get index => _index;
  Track? get current => _queue.isEmpty ? null : _queue[_index];
  bool get playing => _player.playing;
  bool get shuffle => _shuffle;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;

  /// Replaces the queue and starts at [index]. This is the only entry point
  /// used when a track, album, artist or playlist is selected.
  Future<void> setQueue(List<Track> tracks, {required int index, bool shuffle = false}) async {
    if (tracks.isEmpty) return;
    _shuffle = shuffle;
    final safeIndex = index.clamp(0, tracks.length - 1);
    final sources = tracks
        .map((track) => AudioSource.uri(Uri.file(track.path)))
        .toList(growable: false);

    _originalQueue
      ..clear()
      ..addAll(tracks);
    _queue
      ..clear()
      ..addAll(tracks);
    _index = safeIndex;

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: safeIndex,
    );
    onQueueChanged?.call(queue, _index);
    _publishCurrentMedia();
    _publishState();
  }

  /// Restores a saved queue without starting playback.
  Future<void> restoreQueue(List<Track> tracks, {required int index, Duration position = Duration.zero}) async {
    await setQueue(tracks, index: index);
    await _player.seek(position);
    await _player.pause();
  }

  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  Future<void> insertNext(Track track) async {
    final at = (_index + 1).clamp(0, _queue.length);
    _queue.insert(at, track);
    await _rebuildSources(preserveIndex: true);
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _queue.length || _queue.length == 1) return;
    final wasCurrent = index == _index;
    _queue.removeAt(index);
    if (index < _index) _index--;
    await _rebuildSources(preserveIndex: !wasCurrent);
  }

  Future<void> move(int from, int to) async {
    if (from < 0 || to < 0 || from >= _queue.length || to >= _queue.length || from == to) return;
    final track = _queue.removeAt(from);
    _queue.insert(to, track);
    if (from == _index) {
      _index = to;
    } else if (from < _index && to >= _index) {
      _index--;
    } else if (from > _index && to <= _index) {
      _index++;
    }
    await _rebuildSources(preserveIndex: true);
  }

  /// Shuffle is applied to our own queue, not just_audio's shuffle mode.
  /// That keeps [index] aligned with the list shown in the queue sheet.
  Future<void> setShuffle(bool enabled) async {
    if (_shuffle == enabled || _queue.isEmpty) {
      _shuffle = enabled;
      _publishState();
      return;
    }
    _shuffle = enabled;
    final currentPath = _queue[_index].path;
    if (enabled) {
      final rest = _originalQueue.where((t) => t.path != currentPath).toList()..shuffle();
      _queue
        ..clear()
        ..add(_originalQueue.firstWhere((t) => t.path == currentPath))
        ..addAll(rest);
      _index = 0;
    } else {
      _queue
        ..clear()
        ..addAll(_originalQueue);
      final restored = _queue.indexWhere((t) => t.path == currentPath);
      _index = restored < 0 ? 0 : restored;
    }
    await _rebuildSources(preserveIndex: true);
    _publishState();
  }

  Future<void> saveSnapshot() async {
    onPositionSaved?.call(_index, _player.position);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    final index = _queue.indexWhere((track) => track.path == mediaId);
    if (index >= 0) await jumpTo(index);
  }

  Future<void> dispose() async {
    _positionTicker?.cancel();
    await _player.dispose();
  }

  Future<void> _rebuildSources({required bool preserveIndex}) async {
    if (_queue.isEmpty) return;
    final sources = _queue.map((t) => AudioSource.uri(Uri.file(t.path))).toList(growable: false);
    final currentPath = preserveIndex && _index < _queue.length ? _queue[_index].path : null;
    final position = _player.position;
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: _index.clamp(0, _queue.length - 1),
    );
    final shifted = _queue.indexWhere((t) => t.path == currentPath);
    if (shifted >= 0) _index = shifted;
    await _player.seek(position, index: _index);
    onQueueChanged?.call(queue, _index);
    _publishCurrentMedia();
  }

  void _onPlaybackEvent(PlaybackEvent event) {
    // just_audio advances the index itself for a concatenating source;
    // the handler only needs to republish the updated state.
    _publishState();
  }

  void _onCurrentIndex(int? index) {
    if (index == null || index == _index) return;
    if (index >= 0 && index < _queue.length) {
      _index = index;
      onQueueChanged?.call(queue, _index);
      _publishCurrentMedia();
      _publishState();
      onPositionSaved?.call(_index, Duration.zero);
    }
  }

  void _publishCurrentMedia() {
    final track = current;
    if (track == null) return;
    mediaItem.add(MediaItem(
      id: track.path,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: track.duration,
      artUri: track.coverPath == null ? null : Uri.file(track.coverPath!),
    ));
    onTrackChanged?.call(track);
  }

  void _publishState() {
    final state = _player.playbackEvent.processingState;
    playbackState.add(PlaybackState(
      controls: const <MediaControl>[
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: const <MediaAction>{
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const <int>[0, 1, 3],
      processingState: _mapState(state),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      updateTime: DateTime.now(),
    ));
  }

  static AudioProcessingState _mapState(ProcessingState state) => switch (state) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      };
}

import 'package:flutter_test/flutter_test.dart';
import 'package:moni/data/track.dart';

void main() {
  group('Track', () {
    test('parses a numbered "artist - title" filename', () {
      final parsed = Track.parseFileName('/music/Album/03 - Olivia Rodrigo - vampire.flac');
      expect(parsed.$1, 'vampire');
      expect(parsed.$2, 'Olivia Rodrigo');
    });

    test('falls back to the bare filename', () {
      final parsed = Track.parseFileName('/music/No Tag.mp3');
      expect(parsed.$1, 'No Tag');
      expect(parsed.$2, 'Unknown artist');
    });

    test('formats duration without hours', () {
      const track = Track(path: '/a.mp3', title: 'A', artist: 'B', album: 'C', duration: Duration(minutes: 3, seconds: 41));
      expect(track.durationLabel, '03:41');
    });

    test('JSON round trip preserves metadata', () {
      const track = Track(
        path: '/a.flac',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        albumArtist: 'Album Artist',
        trackNumber: 2,
        duration: Duration(seconds: 215),
        year: DateTime(2024),
        genres: <String>['Indie'],
      );
      final restored = Track.fromJson(track.toJson());
      expect(restored, track);
      expect(restored.title, 'Song');
      expect(restored.genres, <String>['Indie']);
      expect(restored.duration, const Duration(seconds: 215));
    });
  });
}

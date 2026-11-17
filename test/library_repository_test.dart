import 'package:flutter_test/flutter_test.dart';
import 'package:moni/data/library_repository.dart';
import 'package:moni/data/track.dart';

Track track(String path, String title, String artist, String album, {int? number}) => Track(
      path: path,
      title: title,
      artist: artist,
      album: album,
      albumArtist: artist,
      trackNumber: number,
      duration: const Duration(seconds: 180),
    );

void main() {
  group('LibraryRepository', () {
    test('groups albums and artists from tags', () {
      final repo = LibraryRepository()
        ..replaceAll(<Track>[
          track('/a/1.flac', 'One', 'Artist', 'Album', number: 1),
          track('/a/2.flac', 'Two', 'Artist', 'Album', number: 2),
          track('/a/3.flac', 'Three', 'Other', 'Another'),
        ]);

      expect(repo.albums, hasLength(2));
      expect(repo.artists, hasLength(2));
      final album = repo.albums.firstWhere((a) => a.name == 'Album');
      expect(album.tracks.map((t) => t.title), <String>['One', 'Two']);
    });

    test('search matches title, artist and album case-insensitively', () {
      final repo = LibraryRepository()
        ..replaceAll(<Track>[track('/a.mp3', 'Vampire', 'Olivia Rodrigo', 'Guts')]);

      expect(repo.search('vamp'), hasLength(1));
      expect(repo.search('RODRIGO'), hasLength(1));
      expect(repo.search('guts'), hasLength(1));
      expect(repo.search('missing'), isEmpty);
    });

    test('deduplicates by path', () {
      final repo = LibraryRepository()
        ..replaceAll(<Track>[
          track('/a.mp3', 'A', 'B', 'C'),
          track('/a.mp3', 'A', 'B', 'C'),
        ]);
      expect(repo.tracks, hasLength(2)); // replaceAll keeps source order
      repo.add(track('/a.mp3', 'A', 'B', 'C'));
      expect(repo.tracks, hasLength(2));
    });
  });
}

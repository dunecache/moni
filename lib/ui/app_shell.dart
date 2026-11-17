import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/library_screen.dart';
import 'screens/listen_screen.dart';
import 'screens/now_playing_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/mini_player.dart';

/// Three destinations. Now Playing is a route, never a tab. Search is reached
/// from Listen; playlists and settings details are contextual pushes.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _openPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NowPlayingScreen()),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SearchScreen(onOpenPlayer: _openPlayer)),
    );
  }

  void _openPlaylist(String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PlaylistScreen(playlistId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ListenScreen(onOpenSearch: _openSearch, onOpenPlayer: _openPlayer),
          LibraryScreen(onOpenSettings: () => setState(() => _index = 2), onOpenPlaylist: _openPlaylist),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(onOpenPlayer: _openPlayer),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.spa_outlined),
                selectedIcon: Icon(Icons.spa_rounded),
                label: 'Listen',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music_rounded),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

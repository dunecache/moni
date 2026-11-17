import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/preferences.dart';
import 'playback/moni_audio_handler.dart';
import 'state/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = MoniPreferences(await SharedPreferences.getInstance());

  // Create the handler up front so the UI can always be injected with a
  // working player, even if native background-audio setup fails.
  final handler = MoniAudioHandler();

  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  } catch (error) {
    debugPrint('Audio session configuration failed: $error');
  }

  try {
    await AudioService.init(
      builder: () => handler,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.moni.player.audio',
        androidNotificationChannelName: 'Playback',
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false,
      ),
    );
  } catch (error) {
    // A platform setup problem must never prevent the app from rendering.
    debugPrint('Background audio service unavailable: $error');
  }

  runApp(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        audioHandlerProvider.overrideWithValue(handler),
      ],
      child: const MoniApp(),
    ),
  );
}

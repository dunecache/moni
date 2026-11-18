# moni

A quiet, local-first music player. No downloads, no extensions, no network
storage, no account — music already on your device, listened to calmly.

The visual language comes from **Kanso Matcha v1.3.0**
(`~/kanso/kanso_design_system`): Morning Matcha for light, Evening Zen for
dark. The semantic token roles are mirrored exactly in
`lib/kanso/kanso_tokens.dart`; that file is the only place in the app that
contains raw color values. The design system's 82/82 contrast gate remains the
authority for any palette change.

## What is in the box

- **Local library** — recursive folder scanning, tag reading via
  `audio_metadata_reader`, album/artist grouping, search.
- **Playback** — `just_audio` behind a single `audio_service` handler:
  background playback, notification and lock-screen controls, queue, shuffle,
  seek, gapless track transitions, saved queue/position on relaunch.
- **Collections** — Loved, ordered playlists, recently played.
- **Player** — artwork-led Now Playing, quiet mini player, reorderable queue.
- **Settings** — Kanso appearance mode and library folder management.

## Architecture

```
lib/
  kanso/       design-system adapter (tokens, theme, motion, shared widgets)
  data/        models, folder scanner, preferences
  playback/    audio_service handler + on-demand artwork
  state/       Riverpod controllers (library, collections, playback)
  ui/          shell, screens, reusable widgets
```

Rules that keep the codebase coherent:

1. No raw colors outside `lib/kanso/kanso_tokens.dart` (enforced by a test).
2. Screens never touch `AudioPlayer`; they call the playback controller, which
   talks to one `MoniAudioHandler`.
3. Now Playing is a route, not a navigation tab. Three primary destinations:
   Listen, Library, Settings.
4. Empty, loading and error surfaces use the shared Kanso components.
5. Theme parity: a component's metrics and action hierarchy never change
   between Morning Matcha and Evening Zen — only color tokens do. Filled
   actions always use the theme-invariant `on-accent` ink; dialogs use the
   neutral `surfaceElevated` role, never the accent-family `floating` role.

## Build and run

```sh
flutter pub get
flutter test
flutter run
```

Native platform folders are generated with `flutter create --platforms=android,ios,linux,macos,windows .`
from a Flutter SDK; this repository intentionally contains only the Dart
project and tests.

### Android media session setup

After generating the platform folders, `audio_service` needs its foreground
service declared in `android/app/src/main/AndroidManifest.xml`, inside
`<application>`:

```xml
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true"
    tools:ignore="Instantiatable">
  <intent-filter>
    <action android:name="android.media.browse.MediaBrowserService" />
  </intent-filter>
</service>
<receiver
    android:name="com.ryanheise.audioservice.MediaButtonReceiver"
    android:exported="true">
  <intent-filter>
    <action android:name="android.intent.action.MEDIA_BUTTON" />
  </intent-filter>
</receiver>
```

Add `<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />`,
`FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK` and `READ_MEDIA_AUDIO`
(Android 13+) with the legacy `READ_EXTERNAL_STORAGE` fallback. This is what
keeps playback, notification controls and lock-screen controls alive in the
background.

### Android note

The library scanner reads regular filesystem paths. On Android, add a folder
that your app can read directly (for example a path under shared storage that
you have granted media/file access to). Content `content://` tree URIs need a
dedicated SAF document reader and are not supported in this first version.

## CI and releases

- `.github/workflows/ci.yml` runs on pushes and pull requests to `main`:
  `flutter analyze`, `flutter test` and the structural/Kanso token check.
- `.github/workflows/release.yml` (**Release Android**) runs on tags matching
  `v*` (or manually): verifies, builds the three split release APKs and uploads
  them to the GitHub Release.
- `.github/workflows/release-desktop.yml` (**Release Desktop**) runs on the same
  tags independently: verifies, builds the Linux x64 bundle, macOS `.app` and
  Windows x64 archive, and uploads them to the same GitHub Release.

The two release pipelines are independent — a failing desktop build does not
block Android, and vice versa. Both use race-safe create-or-update release
publishing, so they can run concurrently for the same tag.

The shared `.github/actions/setup` action installs Flutter (pinned in one
place), generates any missing native platform folders and applies the
`audio_service` Android manifest / iOS background-mode / macOS deployment
configuration before building. Startup is also guarded so a native audio
initialization failure cannot leave the app on a black screen.

Because this repository intentionally contains no native platform folders,
the first CI run generates them from Flutter templates. If you later add
custom native code, commit those folders so the setup step leaves them alone.
Android release builds use Flutter's template signing (debug key) until a
keystore is configured — replace that before distributing through a store.

## Scope decisions

Mornye remains untouched in `~/apps/Mornye` as the reference application. This
project is a deliberate product pivot to a pure local player: downloads,
extension store, network storage, device sync and scrobbling are **not**
included. Everything retained exists to serve local listening.

# GlassChat — Flutter (Android, 1:1 mirror)

Isolated Flutter client mirroring the native iOS GlassChat core screens:
chat list (search, online dots, timestamps, unread badges), chat room
(contact header with call icons, bubbles with delivery status icons,
composer with attachments + voice trigger), profile (dynamic phone bound to
the session user, info card, Media/Files/Links tabs), and settings
(Notifications / Privacy / Appearance / Account).

## Structure

```
lib/
├── core/       # theme + glassmorphic UI elements
├── models/     # User, Chat, Message
├── providers/  # provider-based state (ChatProvider, SettingsProvider)
└── screens/    # chat list, chat room, profile, settings
```

## Build

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

CI (`.github/workflows/flutter-build.yml`) builds the release APKs on every
push to `main`. The native iOS project at the repository root is untouched.

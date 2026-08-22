# GlassChat — Flutter (Android)

Standalone Flutter client mirroring the native iOS GlassChat ecosystem:
chat streams with system bot mini-app launchers (`@wallet`, `@fragment`),
dual-currency wallet (`$TYP0K` / USDT) with photo-KC +50,000 $TYP0K bonus,
and the Fragment collectible username auction.

## Structure

```
lib/
├── core/      # theme, WalletManager, ChatStore (state)
├── models/    # User, Chat, Message
├── views/     # home, chat, profile, wallet / KYC / fragment sheets
└── widgets/   # glass cards, token icons, mini-app pill, message bubbles
```

State management: `provider` (`ChangeNotifier`) — the Dart mirror of the
Swift `@Observable` singletons.

## Build

```bash
flutter pub get
flutter build apk --release --split-per-abi
```

CI (`.github/workflows/flutter-build.yml`) runs the release APK build on
every push to `main` and uploads the split APKs as artifacts.

The native iOS project stays untouched at the repository root.

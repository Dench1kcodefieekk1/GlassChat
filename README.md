# GlassChat

A modern iOS messenger prototype built with **SwiftUI** and **iOS 26 Liquid Glass**.
GlassChat demonstrates the full happy path of a messaging app — chats, sending
text/photo/voice messages, profiles, contacts, search, and settings — entirely
offline, with an architecture designed so the local backend can later be swapped
for a real one.

> GlassChat is an original prototype. It is not affiliated with Telegram or any
> other messaging service, and it uses no third-party assets.

---

## Feature overview

| Area | What works |
| --- | --- |
| Chats list | Pinned, muted, unread badges, verified marks, typing indicator, swipe actions (pin / read / delete), context menu, pull-to-refresh |
| Chat screen | Bubbles with tails, date & unread separators, reply previews, edited/deleted states, delivery checkmarks, reactions, copy/forward/edit/delete, emoji-only messages, Markdown inline links |
| Sending | Instant local send with simulated `sending → sent → delivered → read`, simulated typing + replies in direct chats |
| Photos | PhotosPicker, caption preview sheet, in-bubble thumbnails, full-screen viewer with pinch-to-zoom, ShareLink |
| Camera | System camera capture (on devices that have one) |
| Voice messages | AVAudioRecorder with live level waveform, cancel/send, AVAudioPlayer playback with progress-colored waveform |
| Profile | Large avatar, status, bio/phone/username card, Message/Call/Mute actions, shared media grid, simulated call screen |
| Contacts | Alphabetical grouping, search, online status, start chat |
| Settings | Appearance (light/dark/system + 6 accent colors), chat/notifications/privacy toggles, storage usage, clear cache, edit profile, about/licenses — all persisted |
| Search | Global chat + message search, contacts search |
| Persistence | Everything survives app restarts (JSON store in Application Support) |
| States | Empty chats, empty search, loading images, deleted media placeholders, mic permission alert |
| Accessibility | Dynamic Type, VoiceOver labels, Reduce Transparency via system materials, semantic colors for dark mode |

## Requirements

- **Xcode 26** (for the iOS 26 SDK and Liquid Glass APIs)
- **iOS 26.0** deployment target — run on an iPhone simulator or device with iOS 26
- **XcodeGen** (`brew install xcodegen`) — the `.xcodeproj` is generated from `project.yml`
- No third-party runtime dependencies. Frameworks used: SwiftUI, Foundation,
  Observation, AVFoundation, PhotosUI, UserNotifications, UIKit.

## Opening & running locally

```bash
# 1. Generate the Xcode project from project.yml
brew install xcodegen   # one-time
xcodegen generate

# 2. Open and run
open GlassChat.xcodeproj
# Select an iPhone (iOS 26) simulator and press Cmd+R
```

Signing uses **Automatic** signing by default; select your team in the target's
Signing & Capabilities if you want to run on a physical device.

## Architecture

```
GlassChat/
├── App/            App entry point, tabs/routes, dependency container
├── Models/         Codable domain models (User, Chat, Message, Attachment, Settings)
├── Repositories/   Repository protocols + DataStore (JSON persistence) + demo seeder
├── ViewModels/     @Observable MVVM layer
├── Views/          SwiftUI screens (Chats, Chat, Contacts, Profile, Settings)
├── Services/       Audio recorder/playback, media storage, notifications, presence
└── Theme/          Palette, shapes, date formatting
```

**Backend-ready design.** All data access goes through protocols:

```swift
protocol ChatRepository
protocol MessageRepository
protocol UserRepository
protocol MediaRepository
protocol AuthenticationService
protocol PresenceService
```

Today these are implemented by `DataStore` (an `@Observable` in-memory store
persisted as JSON) plus `MediaService`. To connect a real backend, implement
e.g. `RemoteChatRepository` against your API and inject it — views and view
models stay untouched. Sending, typing, replies and presence are currently
simulated locally inside `ChatViewModel` / `PresenceSimulator`.

## GitHub Actions → IPA

The workflow at `.github/workflows/build.yml`:

1. checks out the repo on a `macos-26` runner,
2. installs XcodeGen and generates the project,
3. archives the app,
4. exports an IPA,
5. uploads it as the **`GlassChat-iOS`** artifact.

It runs on every push to `main`/`master`, on PRs, and manually via
**Actions → Build GlassChat IPA → Run workflow** (you can override the runner there).

### Without secrets (default)

The workflow produces an **unsigned** `GlassChat.ipa` artifact. It proves the
app compiles and packages end-to-end, but an unsigned IPA cannot be installed
on a physical iPhone — use it for verification, or run locally in Xcode instead.

### With signing secrets (installable IPA)

Add these repository secrets (Settings → Secrets and variables → Actions):

| Secret | Description |
| --- | --- |
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded `.p12` distribution/ad-hoc certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password for the `.p12` |
| `KEYCHAIN_PASSWORD` | Any temporary password for the CI keychain |
| `PROVISIONING_PROFILE_BASE64` | Base64-encoded `.mobileprovision` (Ad Hoc, matching your device UDIDs) |
| `PROVISIONING_PROFILE_NAME` | Exact profile name |
| `TEAM_ID` | Your Apple Developer Team ID |

Create the assets in Xcode (or developer.apple.com):

1. Register your device UDID.
2. Create an **Ad Hoc** provisioning profile for bundle id `com.glasschat.app`
   (or change `BUNDLE_ID` in the workflow and `PRODUCT_BUNDLE_IDENTIFIER` in
   `project.yml`).
3. Export the signing certificate as `.p12`, then:
   `base64 -i certificate.p12 | pbcopy` (macOS) to get the base64 value.

Once the secrets exist, the same workflow automatically switches to the signed
path: manual-signing archive → `xcodebuild -exportArchive` → installable
`GlassChat.ipa`.

> Tip: for App Store distribution, switch `method` to `app-store` in the
> generated `ExportOptions.plist` step and use a distribution profile. An App
> Store Connect API key (`App Store Connect API Key` secret flow) is a more
> modern alternative for upload automation.

### Downloading the artifact

Actions → select the run → **Artifacts** → download `GlassChat-iOS`, unzip, and
you'll find `GlassChat.ipa` inside.

## Demo data

On first launch the app seeds a demo environment: you are **Alex (@alex)** with
chats for Sarah, John, Design Team, Family, and iOS Developers, realistic
message history, generated placeholder images (no external assets), unread
counts, a pinned chat, and a muted chat. Deleting chats or clearing cache
persists; to fully reset, delete the app from the simulator.

## Known limitations (prototype scope)

- No real backend: delivery/read states, typing, and replies are simulated.
- No message multi-select, chat folders, archive, or message pinning (chat
  pinning is supported).
- Links are rendered via inline Markdown (`[title](url)`); plain URLs are not
  auto-detected.
- Voice messages seeded by demo data are not included — record your own with
  the microphone button.
- Calls are simulated with a local screen.

## License

MIT — see repository. Built as a demonstration of iOS 26 Liquid Glass design.

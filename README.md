# GlassChat

A modern iOS messenger prototype built with **SwiftUI** and **iOS 26 Liquid Glass**.
GlassChat demonstrates the full happy path of a messaging app — chats, sending
text/photo/voice messages, profiles, contacts, search, and settings — entirely
offline, with an architecture designed so the local backend can later be swapped
for a real one.

> GlassChat is an original prototype. It is not affiliated with Telegram or any
> other messaging service, and it uses no third-party assets.

---

## How this project builds (no Mac required)

This project is designed for **Windows → GitHub → GitHub Actions → IPA**.
You never run Xcode locally; everything compiles on GitHub's macOS runners.

```
Your Windows PC                GitHub                      GitHub Actions (macOS runner)
───────────────                ──────                      ─────────────────────────────
git push  ──────────────►  repository  ──── triggers ───►  1. XcodeGen generates .xcodeproj
                                                            2. Xcode 26 builds & archives
                                                            3. IPA is exported
                        ◄──  artifact "GlassChat-iOS"  ───  4. artifact is uploaded
download .ipa  ◄──────────
```

The pipeline inside `.github/workflows/build.yml`:

| Step | What happens |
| --- | --- |
| 1 | `actions/checkout` fetches the repo on a `macos-26` runner |
| 2 | The newest installed Xcode is selected via `xcode-select` |
| 3 | `brew install xcodegen` then `xcodegen generate` creates `GlassChat.xcodeproj` from `project.yml` |
| 4 | `xcodebuild archive` (Release, `generic/platform=iOS`) |
| 5 | Signed: `xcodebuild -exportArchive` → real IPA. Unsigned: `.app` is zipped into `Payload/` → IPA |
| 6 | `actions/upload-artifact` publishes **GlassChat-iOS** containing `GlassChat.ipa` |

---

## One-time setup from Windows

1. Install [Git for Windows](https://git-scm.com/download/win) (also gives you Git Bash + `openssl`).
2. Create an **empty** repository on GitHub (do **not** add a README there), e.g. `YOUR-NAME/GlassChat`.
3. In this project folder, run in PowerShell or Git Bash:

```powershell
git remote add origin https://github.com/YOUR-NAME/GlassChat.git
git push -u origin main
```

The push triggers the first build automatically.

> **Note:** the manual **Run workflow** button only appears *after* the workflow
> file exists on the default branch — i.e. after this first push.

Then choose one of the two modes below.

---

## Mode A — DEVELOPMENT / TEST (no Apple account, no signing)

**Purpose:** verify that the project compiles and packages in GitHub Actions.
Works out of the box, with zero configuration.

### Run

Either push a commit, or run it manually:

**GitHub → your repo → Actions tab → "Build iOS" (left sidebar) → "Run workflow" button → Run workflow**

### Result

- Artifact **`GlassChat-iOS`** → unzip → `GlassChat.ipa`.
- The build summary states `Mode: UNSIGNED_TEST`.

### Honest limitation

**An unsigned IPA cannot be installed on a physical iPhone.** iOS refuses to run
apps that are not signed with an Apple certificate and provisioning profile.
Mode A is strictly a compilation/packaging check. For a device-installable IPA
use Mode B.

### Where to download the artifact

1. GitHub → repo → **Actions**
2. Click the completed **"Build iOS"** run
3. Scroll to **Artifacts** → click **GlassChat-iOS**
4. Unzip the download; `GlassChat.ipa` is inside

Artifacts are kept for 90 days by default.

---

## Mode B — PHYSICAL IPHONE (signed Ad Hoc IPA)

This produces a real, installable `GlassChat.ipa` signed with **your** Apple
Developer certificate. Everything below can be done from Windows.

### Prerequisites

- An **Apple Developer Program** membership ($99/year) — [developer.apple.com](https://developer.apple.com/programs/)
- Your iPhone's UDID registered in the account
- The six repository secrets listed in step 6

### Step 1 — Get your iPhone UDID (Windows)

1. Install the **Apple Devices** app (Microsoft Store) — or use iTunes.
2. Connect the iPhone via USB and trust the computer.
3. Click the field that shows the serial number repeatedly until it switches to **UDID** (a 25-character string).
4. Copy it.

### Step 2 — Register the device

[developer.apple.com](https://developer.apple.com/account/resources/devices/list) →
**Certificates, Identifiers & Profiles → Devices → +** → paste UDID, name it (e.g. "My iPhone").

### Step 3 — Register the App ID

**Identifiers → +** → *App IDs* → *App* → Description `GlassChat`,
Bundle ID **Explicit**: `com.glasschat.app`.
(This must match `BUNDLE_ID` in the workflow and `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` —
if you change it, change all three.)

### Step 4 — Create the distribution certificate (from Windows, with OpenSSL)

Apple normally expects a CSR from macOS Keychain Access; on Windows you can do
the same with OpenSSL. Open **Git Bash** in any folder:

```bash
# 1. Generate a private key + certificate signing request
openssl req -newkey rsa:2048 -nodes \
  -keyout distribution_private.key \
  -out CertificateSigningRequest.certSigningRequest \
  -subj "/emailAddress=you@example.com/CN=Your Name/C=US"
```

2. On developer.apple.com: **Certificates → +** → under *Distribution* choose
   **Apple Distribution** → upload `CertificateSigningRequest.certSigningRequest`
   → download the resulting `distribution.cer`.

```bash
# 3. Convert Apple's .cer (DER) to PEM
openssl x509 -inform der -in distribution.cer -out distribution.pem

# 4. Bundle key + certificate into a .p12 (you will be asked for an export
#    password — remember it, it becomes APPLE_CERTIFICATE_PASSWORD)
openssl pkcs12 -export -out APPLE_CERTIFICATE.p12 \
  -inkey distribution_private.key -in distribution.pem
```

Keep `distribution_private.key` safe; you don't need it for CI.

### Step 5 — Create the Ad Hoc provisioning profile

1. developer.apple.com → **Profiles → +** → *Distribution* → **Ad Hoc**.
2. App ID: `com.glasschat.app`.
3. Certificate: the **Apple Distribution** one from step 4.
4. Devices: check your iPhone.
5. **Name the profile exactly**, e.g. `GlassChat AdHoc` — this exact string becomes
   the `PROVISIONING_PROFILE_NAME` secret, so avoid characters you'd rather not
   paste into a secret value (plain words/spaces are fine).
6. Download `GlassChat_AdHoc.mobileprovision`.

> You don't put the profile anywhere yourself — the workflow decodes it from the
> secret and installs it into the runner's
> `~/Library/MobileDevice/Provisioning Profiles/` automatically.

### Step 6 — Add the GitHub Secrets

Base64-encode the two binary files in **PowerShell** (one line each, copied to clipboard):

```powershell
# certificate
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\APPLE_CERTIFICATE.p12")) | Set-Clipboard

# provisioning profile
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\GlassChat_AdHoc.mobileprovision")) | Set-Clipboard
```

Then in your repo: **Settings → Secrets and variables → Actions → New repository secret** — add all six:

| Secret name | What it is | Where you get it | Format |
| --- | --- | --- | --- |
| `APPLE_CERTIFICATE_BASE64` | Signing certificate + private key | Step 4: base64 of `APPLE_CERTIFICATE.p12` | Single-line base64 (PowerShell command above) |
| `APPLE_CERTIFICATE_PASSWORD` | Password protecting the `.p12` | The export password you typed in step 4 | Plain text |
| `KEYCHAIN_PASSWORD` | Throwaway password for the temporary CI keychain | Invent any string, e.g. `glasschat-ci-123` | Plain text |
| `PROVISIONING_PROFILE_BASE64` | The Ad Hoc profile | Step 5: base64 of the `.mobileprovision` | Single-line base64 |
| `PROVISIONING_PROFILE_NAME` | Exact profile name from step 5 | e.g. `GlassChat AdHoc` | Plain text, must match 1:1 |
| `TEAM_ID` | Your 10-character Team ID | developer.apple.com → Membership details | Plain text |

### Step 7 — Run the build

Same as Mode A: **Actions → Build iOS → Run workflow**.
The workflow detects the secrets automatically and switches to the signed path
(build summary shows `Mode: SIGNED_AD_HOC`). Download the artifact the same way.

### Step 8 — Install the IPA on your iPhone (from Windows)

An Ad Hoc IPA is already signed, but Windows has no Xcode to install it. Use a
free sideloading tool:

- **Sideloadly** (sideloadly.io) — pick `GlassChat.ipa`, your Apple ID, and the device.
- **AltServer / AltStore** (altstore.io) — Windows version installs signed IPAs too.

Requirements: the iPhone must be the one whose UDID is inside the provisioning
profile, and the Ad Hoc certificate/profile are valid for 1 year — regenerate
them and update the secrets when they expire.

(Alternative: host the IPA with a `manifest.plist` and install over-the-air via
an `itms-services://` link — useful for sharing with testers.)

---

## Troubleshooting the CI build

| Symptom | Cause / fix |
| --- | --- |
| `xcodegen: command not found` or brew failure | Transient runner/brew issue — re-run the workflow; the step installs XcodeGen fresh each time |
| `No profiles for 'com.glasschat.app' were found` | `PROVISIONING_PROFILE_NAME` doesn't match the profile's real name, or the profile doesn't include the App ID/certificate |
| `errSecInternalComponent` / codesign fails | Wrong `APPLE_CERTIFICATE_PASSWORD`, or the `.p12` base64 contains line breaks — re-copy with the PowerShell command |
| `Provisioning profile ... doesn't include signing certificate` | Profile was created before/without the step-4 certificate — recreate the profile selecting that certificate |
| Device won't install the IPA | Device UDID not registered in the profile, or profile expired |
| Build runs but you expected signing | Secrets missing or misspelled — the summary says `UNSIGNED_TEST`; check all six secret names exactly |
| `workflow_dispatch` button missing | Push at least once so the workflow file exists on the default branch |

---

## Switching to App Store distribution

In `.github/workflows/build.yml`, change the generated `ExportOptions.plist`:
`method` → `app-store`, remove the `provisioningProfiles` dict, and use an
App Store distribution profile. For automated TestFlight uploads, an App Store
Connect API key (`xcrun altool` / `xcrun notarytool`-style tooling or
`iTMSTransporter`) is the more modern route.

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

## Tech requirements (CI-side, for reference)

- **Xcode 26** with the iOS 26 SDK (provided by the `macos-26` runner; the
  workflow auto-selects the newest Xcode installed)
- **iOS 26.0** deployment target
- **XcodeGen** generates the `.xcodeproj` from `project.yml` on CI — you never
  need it locally unless you want to open the project on some Mac
- No third-party runtime dependencies: SwiftUI, Foundation, Observation,
  AVFoundation, PhotosUI, UserNotifications, UIKit

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

## Demo data

On first launch the app seeds a demo environment: you are **Alex (@alex)** with
chats for Sarah, John, Design Team, Family, and iOS Developers, realistic
message history, generated placeholder images (no external assets), unread
counts, a pinned chat, and a muted chat. Deleting chats or clearing cache
persists; to fully reset, delete the app.

## Known limitations (prototype scope)

- No real backend: delivery/read states, typing, and replies are simulated.
- No message multi-select, chat folders, archive, or message pinning (chat
  pinning is supported).
- Links are rendered via inline Markdown (`[title](url)`); plain URLs are not
  auto-detected.
- Calls are simulated with a local screen.
- Unsigned (Mode A) IPAs cannot run on a physical iPhone — by design of iOS.

## License

MIT — built as a demonstration of iOS 26 Liquid Glass design.

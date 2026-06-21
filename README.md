# Lexicon Lock

A focus app that gates distracting apps behind a short spaced-repetition
flashcard review. The framing is a **reward, not a punishment**: *do your reps,
earn your scroll time.*

> v1 targets adult language/vocabulary learners, local-only (no backend, no
> accounts). The architecture is set up so a **parent-controlled kids' mode** and
> **test-prep deck types** can be added later without rewriting the core.

---

## Repository layout

```
.
├─ LearningGateCore/        Pure, reusable Swift package (no UIKit / Screen Time)
│  ├─ Sources/LearningGateCore/   model, stores, schedulers, importers, gate, unlock, stats
│  ├─ Sources/CSQLite/            system libsqlite3 shim (for .apkg)
│  └─ Tests/                      unit tests (run in CI on Linux)
├─ LexiconLockApp/          The iOS app + 3 Screen Time extensions
│  ├─ project.yml                 XcodeGen spec (generates the .xcodeproj)
│  ├─ App/                        SwiftUI app (onboarding, review, decks, stats, settings)
│  ├─ Shared/                     App Group + shield helpers shared with extensions
│  ├─ ShieldConfigurationExt/     custom shield appearance
│  ├─ ShieldActionExt/            shield button handling
│  └─ DeviceActivityMonitorExt/   re-applies the shield when a break ends
├─ .github/workflows/       CI: swift test for LearningGateCore on Linux
├─ VERIFY.md                Device-only checks + unverified Screen Time API symbols
└─ README.md
```

### Why a separate `LearningGateCore`
The core (deck model, card store, SR scheduler, blocking *interface*,
unlock-session logic) is a standalone Swift package with **no dependency on the
app, UIKit, or the Screen Time frameworks**. That keeps it unit-testable on plain
Swift (incl. Linux CI) and reusable by the planned kids-mode and test-prep
features. Two seams make those extensions drop-in:
- **`DeckSource`** protocol — `LocalDeck` now; remote / parent-assigned later.
- **`GateController`** protocol — `IndividualGateController` now (self-control);
  a `ParentControlledGateController` can return `canCurrentUserEditPolicy == false`
  and gate changes behind a passcode, with no change to the unlock loop or UI.

The Screen Time concrete implementation (`ScreenTimeBlockingController`) lives in
the **app**, conforming to the core's `BlockingController` protocol.

---

## Build

### 1. Generate the Xcode project
The `.xcodeproj` is generated from `LexiconLockApp/project.yml` so it doesn't
have to be committed as a giant file.

```bash
brew install xcodegen
cd LexiconLockApp
xcodegen generate          # → LexiconLock.xcodeproj
open LexiconLock.xcodeproj
```

### 2. Capabilities you must enable by hand (Signing & Capabilities)
For **each** of the four targets unless noted:

| Capability | Targets | Notes |
|---|---|---|
| **App Groups** | app + all 3 extensions | One shared group, e.g. `group.<your>.lexiconlock`. Must be identical everywhere. |
| **Family Controls** | app + all 3 extensions | The development entitlement is added by this capability. |

Then replace the placeholder App Group ID **`group.com.example.lexiconlock`** in:
- `LexiconLockApp/App/LexiconLock.entitlements`
- `LexiconLockApp/ShieldConfigurationExt/ShieldConfigurationExt.entitlements`
- `LexiconLockApp/ShieldActionExt/ShieldActionExt.entitlements`
- `LexiconLockApp/DeviceActivityMonitorExt/DeviceActivityMonitorExt.entitlements`
- `LexiconLockApp/Shared/AppGroup.swift` (`AppGroup.id`)

Set your **Development Team** on all targets (or add `DEVELOPMENT_TEAM` in
`project.yml` and re-generate).

### 3. The Family Controls **distribution** entitlement (you handle this)
`FamilyControls` works on a development build with a registered device. To ship,
you must **request the Family Controls (Distribution) entitlement from Apple**
(<https://developer.apple.com/contact/request/family-controls-distribution>) and
add it to your App ID. Code signing, provisioning, and real-device deployment are
your responsibility (per project scope).

### 4. Run the core tests
```bash
cd LearningGateCore
swift test        # macOS, or Linux with libsqlite3-dev + zlib1g-dev installed
```
CI runs this automatically on every push (`.github/workflows/core-tests.yml`).

---

## How the unlock loop works
1. Onboarding requests individual Screen Time authorization and uses
   `FamilyActivityPicker` to choose apps/categories. Tokens are stored opaquely.
2. The shield is applied to those tokens via `ManagedSettingsStore`.
3. Tapping a gated app shows the custom shield with a **"Learn to unlock"** button.
4. The button records intent in the App Group; the user opens Lexicon Lock, which
   starts a review of **N due cards** (default 5).
5. On passing (default: recall all N), the shield is cleared for **X minutes**
   (default 10) and a one-shot `DeviceActivitySchedule` is started.
6. When the break ends, the `DeviceActivityMonitor` extension re-applies the shield.

`N` and `X` are configurable in **Settings** (backed by `GatePolicy`).

> ⚠️ Several Screen Time behaviors can only be validated on a real device (the
> shield never renders in the Simulator), and a few API symbols couldn't be
> compile-checked in the build environment used to author this. **See
> [VERIFY.md](VERIFY.md)** for the full manual checklist and the specific symbols
> to confirm — including the known limitation that an extension cannot directly
> launch the host app.

## Decks
- **CSV**: `front,back[,tags]` (quoted fields & a `front,back` header supported).
- **Anki `.apkg`**: export with *"Support older Anki versions"* enabled so the
  collection is `collection.anki2`/`anki21` (the newer zstd `anki21b` is not
  supported). Parsing happens in the app and results are shared via the App Group
  — extensions stay lightweight.

## Spaced repetition
- **SM-2** is the primary scheduler (`SM2Scheduler`); **Leitner**
  (`LeitnerScheduler`) is a simpler fallback. Both are pure and unit-tested.

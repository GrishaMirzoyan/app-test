# VERIFY.md — manual / device-only verification

The pure logic in `LearningGateCore` is unit-tested and runs in CI on Linux
(`swift test`). Everything below **cannot** be verified in this environment (no
Xcode, and the shield never renders in the Simulator). Work through it on a real
device after you've enabled the capabilities in the README.

Legend: ⛏️ = a Screen Time API symbol/signature I could not compile-check here —
confirm it builds before relying on it (these are the project's "don't
hallucinate the API" items).

---

## 0. Build the project (Mac, one-time)
- [ ] `brew install xcodegen`
- [ ] `cd LexiconLockApp && xcodegen generate` produces `LexiconLock.xcodeproj`.
- [ ] Open it; set your **Development Team** on all four targets.
- [ ] Replace the App Group ID `group.com.example.lexiconlock` everywhere
      (entitlements ×4, `Shared/AppGroup.swift`) with your real group.
- [ ] App builds for an iOS 17 device (not just Simulator).

## 1. FamilyControls authorization ⛏️
- [ ] Onboarding "Enable Screen Time" calls
      `AuthorizationCenter.shared.requestAuthorization(for: .individual)` and the
      system prompt appears.
- [ ] After approving, `authorizationStatus == .approved` and the app advances
      to app selection.
- [ ] Confirm `AuthorizationStatus` cases used (`.approved`) match the SDK.

## 2. FamilyActivityPicker ⛏️
- [ ] `.familyActivityPicker(isPresented:selection:)` presents the system picker.
- [ ] `FamilyActivitySelection` is `Equatable` (the `.onChange(of: selection)`
      in `OnboardingView`/`SettingsView` depends on this) — confirm it compiles.
- [ ] Chosen selection persists across launches (stored in the App Group).
- [ ] We never display app names anywhere (tokens are opaque — by design).

## 3. Applying the shield ⛏️
File: `Shared/ShieldApplier.swift`, `Shared/ScreenTimeBlockingController.swift`.
- [ ] `ManagedSettingsStore(named: .init("lexiconLockGate"))` — confirm the
      `ManagedSettingsStore.Name` initializer signature.
- [ ] `store.shield.applications = Set<ApplicationToken>` blocks the picked apps.
- [ ] `store.shield.applicationCategories = .specific(categoryTokens)` — confirm
      the `ShieldSettings.ActivityCategoryPolicy` case name `.specific`.
- [ ] `store.shield.webDomains` behaves for web domains.
- [ ] Tapping a gated app shows a shield.

## 4. Custom shield appearance ⛏️ (Simulator can't render this)
File: `ShieldConfigurationExt/ShieldConfigurationProvider.swift`.
- [ ] `ShieldConfigurationDataSource` override names compile:
      `configuration(shielding: Application)`,
      `configuration(shielding: Application, in: ActivityCategory)`,
      `configuration(shielding: WebDomain)`,
      `configuration(shielding: WebDomain, in: ActivityCategory)`.
- [ ] `ShieldConfiguration(backgroundBlurStyle:backgroundColor:icon:title:
      subtitle:primaryButtonLabel:primaryButtonBackgroundColor:)` initializer
      signature is correct.
- [ ] `ShieldConfiguration.Label(text:color:)` exists.
- [ ] On device, the shield shows "Earn your break" + "Learn to unlock" button.

## 5. Shield action → main app ⚠️ KNOWN LIMITATION
File: `ShieldActionExt/ShieldActionHandler.swift`.
- [ ] `ShieldActionDelegate` overrides compile for application / category /
      webDomain tokens; `ShieldAction` cases `.primaryButtonPressed` /
      `.secondaryButtonPressed` and `ShieldActionResponse` cases
      `.close` / `.defer` / `.none` are correct. ⛏️
- [ ] **An extension cannot launch the host app.** Current behavior: primary
      button sets `pendingUnlockRequested` in the App Group and returns `.close`
      (sends the user home). Verify the UX: does the user understand to open
      Lexicon Lock? **Decision needed:** is "close + nudge" acceptable, or should
      we post a tappable local notification from the extension that deep-links
      into the app? (Not implemented — needs your call.)
- [ ] When the app next becomes active, `RootView` sees the flag and opens the
      review sheet.

## 6. Unlock → grant break → re-shield ⛏️ (the riskiest timing path)
Files: `ScreenTimeBlockingController.grantBreak`, `DeviceActivityMonitorExt`.
- [ ] Passing a review calls `grantBreak(for:)`, which clears the shield — the
      gated app opens immediately.
- [ ] Lesson path: completing a lesson credits the TimeBank; "Unlock my apps"
      redeems the whole balance into a single `grantBreak(for:)` call. **Note
      the granularity caveat below applies doubly here** — a 1-minute break
      (one lesson, default policy) is at the DeviceActivitySchedule's minimum
      precision. If 1-minute windows prove unreliable on device, raise the
      default `timePerLesson` or require a minimum banked balance to redeem.
- [ ] `DeviceActivityCenter().startMonitoring(_:during:)` with a
      `DeviceActivitySchedule(intervalStart:intervalEnd:repeats:false)` from
      *now* to *now + X* is accepted. Confirm this one-shot use is valid and the
      `DeviceActivityName`/`startMonitoring` signatures compile.
- [ ] When the window ends, `GateActivityMonitor.intervalDidEnd` fires and the
      shield is re-applied. **Verify timing precision** (schedule granularity is
      to the minute; sub-minute breaks may be imprecise).
- [ ] Edge case: a break that crosses midnight (start/end `DateComponents` wrap)
      still re-shields correctly.
- [ ] The DeviceActivity monitor extension stays within its memory budget (it
      deliberately does **not** link `LearningGateCore`).

## 7. App Group data sharing
- [ ] Cards/decks imported in the app are visible to the extensions (they read
      the same container). Confirm `FileManager.containerURL(
      forSecurityApplicationGroupIdentifier:)` returns non-nil on device.
- [ ] Policy (N cards / X minutes) edited in Settings is reflected by the gate.

## 8. Importers on device
- [ ] Import a real `.apkg` exported from Anki ("Support older Anki versions"
      checked, so it's `collection.anki2`/`anki21`, not zstd `anki21b`).
- [ ] Import a CSV.
- [ ] Cards appear; reviewing them advances their schedule.

---

## Dependency notes
- **ZIPFoundation** is pinned `<1.0`; `ApkgDeckImporter` uses the 0.9.x failable
  `Archive(url:accessMode:)`. If you bump to 1.0+, that initializer becomes
  throwing and the importer must be updated.
- **CSQLite** links the system `libsqlite3` (present on iOS; on the Linux CI we
  `apt-get install libsqlite3-dev`).

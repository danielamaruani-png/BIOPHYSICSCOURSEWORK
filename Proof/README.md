# Proof — Phase 1 (MVP)

A social accountability app whose only content is proof of progress:
one photo per resolution per day, streaks, and a friends list that
shows completion status only by default — never a feed, unless two
people mutually opt in to become accountability partners.

This folder is a native iOS (SwiftUI) app. It was written in a
Linux container without Xcode, so **none of this has been compiled or
run yet** — the code follows standard SwiftUI/Firebase patterns, but
treat first build as the point where real bugs will surface.

## What's implemented (Phase 1 scope)

- Sign in with Apple + Google (Firebase Auth)
- Profile: name, photo, bio
- Resolution creation: name, category, start date, frequency, color/icon
- Daily proof: photo + optional 100-char caption, one per resolution
  per day (enforced by using the date as the Firestore document ID)
- Home screen: today's missions (✅/⭕) + "Add Today's Proof" button
- Progress: current/longest streak, lifetime completion %, calendar
  heatmap, proof count
- Friends: one-way follow, see today's completion status only
- Accountability partners: either side can request to share actual
  proof photos; only takes effect once the other side accepts. Once
  accepted, both can browse each other's resolutions and proof photos
  (read-only — no capture, no editing someone else's data)
- Home screen widget: shows today's actual proof photo (small size)
  with the streak overlaid on top, BeReal-style; the medium size adds
  a second tile with one accepted partner's photo and streak too

## Prerequisites

- A Mac with Xcode 15+
- An Apple Developer account (required for Sign in with Apple and the
  App Group the widget uses)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A Firebase project

## Setup

1. **Firebase project**
   - Create a project at console.firebase.google.com
   - Add an iOS app with bundle ID `com.proofapp.Proof`
   - Download `GoogleService-Info.plist`
   - Enable **Authentication** providers: Apple, Google
   - Enable **Firestore** (production mode) and **Storage**
   - Deploy the security rules in this folder:
     ```
     firebase deploy --only firestore:rules,storage:rules
     ```
     (or paste `firestore.rules` / `storage.rules` into the console's
     Rules tabs). `storage.rules` reads Firestore (`firestore.get`/
     `firestore.exists`) to check accepted accountability-partner
     status before releasing a proof photo, so both services need to
     be enabled in the same project for that check to work.

2. **App Group** (needed for the widget to read streak data)
   - In your Apple Developer account, create an App Group with the
     identifier `group.com.proofapp.shared`
   - `project.yml` already requests this entitlement for both the app
     and widget targets — you just need the ID to exist and your team
     to have access to it.

3. **Generate the Xcode project**
   ```
   cd Proof
   xcodegen generate
   open Proof.xcodeproj
   ```

4. **Wire up Google Sign-In's URL scheme**
   - Open the downloaded `GoogleService-Info.plist`, copy the
     `REVERSED_CLIENT_ID` value
   - In `project.yml`, replace `REPLACE_WITH_REVERSED_CLIENT_ID` under
     `targets.Proof.info.properties.CFBundleURLTypes` with that value,
     then re-run `xcodegen generate`
     (or edit it directly in Xcode's target Info tab — either works,
     but re-running xcodegen will overwrite a direct edit)

5. **Add `GoogleService-Info.plist` to the project**
   - Drag it into the `Proof/Proof` group in Xcode
   - Check "Copy items if needed" and target membership = `Proof`

6. **Set your Team ID**
   - Either fill in `DEVELOPMENT_TEAM` in `project.yml` and regenerate,
     or set it in Xcode's Signing & Capabilities tab for both targets

7. **Build & run** on a device or simulator running iOS 16+.
   Sign in with Apple requires a real device or a simulator signed
   into a real Apple ID under Settings; it does not work in every
   simulator configuration.

## Architecture notes

- **Data model**: `users/{uid}` holds the private profile and nested
  `resolutions/{id}/proofs/{yyyy-MM-dd}`. A separate `publicProfiles/{uid}`
  collection holds only what friends are allowed to see (name, photo,
  streak, today's completion) — this denormalization is what keeps a
  friend's photos and captions out of reach without complex rules.
- **Streaks** are updated client-side in a Firestore transaction
  (`StreakEngine`) right after a proof is written. There's no Cloud
  Function in Phase 1 — fine for MVP, but if streak integrity ever
  needs to be tamper-proof against a modified client, that logic
  should move server-side.
- **Widget data** flows through a shared App Group `UserDefaults`
  (`WidgetSnapshot`), written by the main app whenever resolutions are
  refreshed. The widget extension never talks to Firebase directly —
  it just reads that snapshot, which means it can go stale until the
  app is reopened. Acceptable for Phase 1; a real background refresh
  would need a Firestore listener kept alive via BGAppRefreshTask.
- The `WidgetSnapshot` struct is duplicated between `Proof/Services`
  and `ProofWidget` rather than shared, to keep the widget target a
  simple drop-in folder. If the shared surface grows, promote both to
  a local Swift package instead of keeping them in sync by hand.
- **Accountability partners** are a separate, mutual-consent layer on
  top of following: `PartnerRequest` docs are keyed by the two uids
  sorted into one deterministic ID (`PartnerRequest.pairId`), so
  there's exactly one relationship per pair and both `firestore.rules`
  and `storage.rules` can check "are these two people partners" with a
  single `exists`/`get` instead of a query. Only an *accepted* request
  unlocks reading someone's `resolutions`/`proofs` and their Storage
  photos; a plain follow never does, by design — see the "Guiding
  Principles" in the product roadmap this app is built from.
- **Widget photos** (`WidgetPhotoCache` / `WidgetPhotoLoader`) are
  cached as plain JPEG files in the same shared App Group container,
  separate from `WidgetSnapshot`'s `UserDefaults` — large binary blobs
  don't belong in `UserDefaults`. The main app writes: your own photo
  right after `CaptureProofViewModel.submit()` succeeds (reusing the
  `UIImage` already in memory instead of re-downloading it), and one
  accepted partner's photo — only if they've completed *today* —
  whenever `SessionViewModel.refreshPartners()` runs. Files are named
  `<uid>.jpg`, so both sides of the widget just need to know a uid,
  never a URL. A partner's photo is only ever fetched and only ever
  shown when their `completedToday` flag is true, which is what stops
  a stale cached file from ever being mistaken for today's proof.
- **Privacy note**: putting an actual proof photo on the home screen
  widget means it's visible to anyone glancing at the phone or its
  lock screen widgets — a bigger exposure than the app's own "not
  their entire life" default. Worth a deliberate call (a Settings
  toggle to fall back to the streak-only widget?) before shipping,
  not just an emergent side effect of this implementation.

## Known gaps going into first build

- No unit or UI tests yet.
- `completionPercentage` in `ProgressViewModel` treats every frequency
  as if it were daily — it doesn't yet ease the target for `weekdays`
  or `timesPerWeek` resolutions.
- No image compression/resizing beyond JPEG quality — large camera
  photos upload at full resolution.
- No push notification when someone sends a partner request — they'll
  only see it next time they open the Friends tab.
- No UI to revoke an accepted partnership once granted (only accept/
  decline at request time). Deleting the `partnerRequests` doc would
  do it server-side; add a "Remove partner" action before shipping.
- Widget photo cache only ever holds the *one* featured partner
  (whoever `partnerStreaks.first { $0.completedToday }` picks) — with
  several accepted partners posting the same day, only one photo gets
  cached/shown, and yesterday's featured partner's file lingers
  unused in the App Group container instead of being cleaned up.

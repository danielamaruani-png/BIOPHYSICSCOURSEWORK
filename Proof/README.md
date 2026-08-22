# Proof

A general-purpose accountability app whose only unit is the crew —
there's no solo goal anymore, joining or creating a crew *is* the goal.
Sport, food, work, whatever: post a live camera photo as proof you
showed up, build a streak, unlock real-world rewards, and optionally
show up in a BeReal-style public Feed alongside strangers who also
opted in.

This folder is a native iOS (SwiftUI) app. It was written in a Linux
container without Xcode, so **none of this has been compiled or run
yet** — the code follows standard SwiftUI/Firebase patterns, but treat
first build as the point where real bugs will surface. There's also no
Mac available in the environment this was written in, so getting this
onto the App Store needs a Mac (or a cloud Mac build service) and an
Apple Developer Program account ($99/year) that this session can't set
up on your behalf.

This is a full rewrite of an earlier "Phase 1" version of this app (a
solo daily-proof-photo tracker with 1:1 accountability partners only,
no communities). If you're looking at git history and see references
to `Resolution`, `DailyProof`, or a "Today" tab, that's the old model —
none of it exists anymore.

## What's implemented

- Sign in with Apple + Google (Firebase Auth)
- Profile: name, photo, bio, Local city/region (free text, editable),
  a "Public feed" opt-in toggle
- **Communities** tab: "My Crews" (private crews you belong to) and
  "Local" (public crews, events, and challenges scoped to your city) —
  search, join, and a `+` menu to create a new crew, event, or
  challenge
- Crew creation: name, free-text vibe (not a preset category list),
  icon, colour. Visibility is automatic, not a manual toggle — created
  from My Crews it's private (invite friends by search); created from
  Local it's public
- Crew chat: a "checked in today" banner, a feed of proof photos and
  messages (message composing is intentionally not wired up yet — see
  Known gaps), and a camera button
- **Live-camera-only proof capture** — there is no "choose from
  library" option anywhere; a photo has to be taken on the spot,
  BeReal-style anti-cheat
- **Feed** tab: a BeReal-style public feed of proof photos from anyone
  with the Public feed toggle on — not just crew-mates or friends —
  with per-emoji reactions (several at once, not mutually exclusive)
  and comments
- **Rewards**: a global milestone ladder (e.g. "🔥 30-day streak → new
  pan") shown on Profile with unlocked/locked state and "N days to go"
- **Creator Tools**: only visible to a user whose `UserProfile.isCreator
  == true` — add/edit/delete global Rewards, and create "boosted"
  public crews that get pinned at the top of Local discovery
- Friends tab: search, send/accept/decline accountability-partner
  requests. This is now a purely social relationship (no longer
  unlocks any data access — see Architecture notes)
- Home screen widget: a spotlight tile (a crew member's photo who
  checked in today, with the crew's streak badge) plus, at medium
  size, a "your streak vs. how many of the crew checked in today"
  stat-split card. A camera button on the tile deep-links straight into
  that crew's capture sheet (`proof://capture?crewId=...`)
- Push notification: when an accepted accountability partner posts a
  proof anywhere, you get "{name} completed today's proof! 🎉" — the
  one piece of server-side logic in the app (`functions/`), since
  fanning out to someone else's device isn't something a client can do
  on its own

## Prerequisites

- A Mac with Xcode 15+
- An Apple Developer account (required for Sign in with Apple and the
  App Group the widget uses, and eventually for App Store submission)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A Firebase project

## Setup

1. **Firebase project**
   - Create a project at console.firebase.google.com
   - Add an iOS app with bundle ID `com.proofapp.Proof`
   - Download `GoogleService-Info.plist`
   - Enable **Authentication** providers: Apple, Google
   - Enable **Firestore** (production mode), **Storage**, and **Cloud
     Messaging** (push) — Cloud Messaging needs no setup beyond
     turning it on; its APNs key gets configured in step 2
   - Deploy the security rules in this folder:
     ```
     firebase deploy --only firestore:rules,storage:rules
     ```
     (or paste `firestore.rules` / `storage.rules` into the console's
     Rules tabs). `storage.rules` reads Firestore (`firestore.get`/
     `firestore.exists`) to check crew membership and the public-feed
     opt-in before releasing a proof photo, so both services need to
     be enabled in the same project for that to work.
   - Deploy the Cloud Function that sends the partner-proof push:
     ```
     cd functions && npm install && cd ..
     firebase use --add   # pick your project, alias it "default"
     firebase deploy --only functions
     ```
     This needs the Blaze (pay-as-you-go) plan — Cloud Functions don't
     run on the free Spark plan. In practice this function fires at
     most a few times a day per user, well within Blaze's free tier.
   - **Seed the first creator**: firestore.rules deliberately makes
     `isCreator` un-settable by the user themselves. After you sign in
     once, open the Firestore console and manually flip
     `users/{your-uid}.isCreator` to `true` — that's the only way
     Creator Tools ever becomes reachable for anyone.
   - **Seed the Rewards ladder**: the `rewards` collection starts
     empty. Either add a few docs by hand in the console (`days`,
     `icon`, `label`) or sign in as a creator and use Creator Tools →
     "+ Add" once the app is running.

2. **APNs key for push** (needed for `notifyPartnersOnProof` to
   actually reach devices)
   - Apple Developer account → Certificates, IDs & Profiles → Keys →
     create a key with **Apple Push Notifications service (APNs)**
     enabled, download the `.p8` file
   - Firebase console → Project settings → Cloud Messaging → Apple
     app configuration → upload that `.p8` key with its Key ID and
     your Team ID

3. **App Group** (needed for the widget to read streak data)
   - In your Apple Developer account, create an App Group with the
     identifier `group.com.proofapp.shared`
   - `project.yml` already requests this entitlement for both the app
     and widget targets — you just need the ID to exist and your team
     to have access to it.

4. **Generate the Xcode project**
   ```
   cd Proof
   xcodegen generate
   open Proof.xcodeproj
   ```

5. **Wire up Google Sign-In's URL scheme**
   - Open the downloaded `GoogleService-Info.plist`, copy the
     `REVERSED_CLIENT_ID` value
   - In `project.yml`, replace `REPLACE_WITH_REVERSED_CLIENT_ID` under
     `targets.Proof.info.properties.CFBundleURLTypes` with that value,
     then re-run `xcodegen generate`
     (or edit it directly in Xcode's target Info tab — either works,
     but re-running xcodegen will overwrite a direct edit). Leave the
     second `CFBundleURLSchemes` entry (`proof`) alone — that one's the
     widget's deep-link scheme and doesn't need editing.

6. **Add `GoogleService-Info.plist` to the project**
   - Drag it into the `Proof/Proof` group in Xcode
   - Check "Copy items if needed" and target membership = `Proof`

7. **Set your Team ID**
   - Either fill in `DEVELOPMENT_TEAM` in `project.yml` and regenerate,
     or set it in Xcode's Signing & Capabilities tab for both targets

8. **Build & run** on a device or simulator running iOS 16+.
   Sign in with Apple requires a real device or a simulator signed
   into a real Apple ID under Settings; it does not work in every
   simulator configuration. Push notifications, the camera (proof
   capture is camera-only, no simulator photo library fallback), and
   the widget's deep-link camera button all need a real device.

## Path to the App Store (once this compiles)

This README stops at "builds and runs" — actually shipping needs, at
minimum: an Apple Developer Program enrollment, App Store screenshots
and an icon (there's a design direction already established in the
interactive HTML mockup this codebase mirrors — see the artifact link
shared earlier in this project), a privacy policy URL (required by App
Store Connect given this app collects photos and location-adjacent
city data), a TestFlight beta round, and switching
`project.yml`'s `aps-environment` from `development` to `production`.
None of that is code — it's account setup and content, worth tackling
as its own pass once the app actually runs on a device.

## Architecture notes

- **Data model**: `crews/{crewId}` is the only "goal" object — no more
  per-user `resolutions`. Each crew has a `members` subcollection
  (per-member streak, `doneToday`) and a `feed` subcollection (proof
  photos + messages). `memberUids` is denormalized onto the crew doc
  itself (alongside the `members` subcollection) purely so "my crews"
  can be queried with a single `array-contains` — Firestore can't
  query "does this subcollection contain doc X" across many parent
  docs without collection-group indexing overhead this app doesn't
  need yet.
- A crew holds **at most one active event and one active challenge at
  a time**, embedded directly on the crew doc (`CrewEvent?`,
  `CrewChallenge?`) — creating a new one replaces it. City-wide
  equivalents (`localEvents`, `localChallenges`) are separate
  top-level collections instead, since Local isn't a single crew.
- **Streaks** are updated client-side in a Firestore transaction
  (`StreakEngine`), scoped to a crew member's doc now instead of a
  resolution. There's still no Cloud Function computing streaks
  server-side — same tamper-integrity caveat as before, now scoped per
  crew instead of per resolution.
- **The public Feed is opt-in, not automatic**: posting to a crew and
  mirroring that same photo into `publicFeed` are two explicit steps
  (`FirestoreService.postCrewProof` then
  `postToPublicFeedIfOptedIn`), gated by `UserProfile.publicFeedOptIn`.
  `storage.rules` treats the toggle as all-or-nothing per user (rather
  than tracking "was this specific photo mirrored") — see that file's
  comment for why.
- **Reactions** support multiple emoji per user per post at once (tap
  ❤️ then 🔥 and both stick; tap ❤️ again and only that one clears) —
  `FeedReaction` docs are keyed `{uid}_{emoji}` rather than just `{uid}`
  to make that possible. `reactionCounts`/`commentCount` on the post
  doc are denormalized and kept in sync by a Firestore transaction
  (reactions) or a plain increment (comments).
- **Accountability partners no longer unlock any data access** — that
  was Phase 1's whole reason for `PartnerRequest` existing (it gated
  reading someone's `resolutions`/proof photos). Now crew feed access
  is purely membership-based, so being partners is just the Friends
  tab's social relationship: search, request, accept/decline, see
  their total streak and crew count (already public via
  `publicProfiles` regardless of partner status).
- **Widget data** flows through a shared App Group `UserDefaults`
  (`WidgetSnapshot`), written by `SessionViewModel.syncWidgetSnapshot()`
  whenever crews are refreshed. It auto-picks whichever crew has the
  user's highest streak as the "featured" one for the widget — there's
  no way to manually choose a different crew from the widget yet; that
  would need an `AppIntent`-backed interactive widget configuration
  (iOS 17+), called out here as a follow-up rather than half-built.
- The `WidgetSnapshot` struct is duplicated between `Proof/Services`
  and `ProofWidget` rather than shared, to keep the widget target a
  simple drop-in folder. If the shared surface grows, promote both to
  a local Swift package instead of keeping them in sync by hand.
- **Widget photos** (`WidgetPhotoCache`/`WidgetPhotoLoader`) are cached
  as plain JPEG files in the same shared App Group container, keyed by
  uid — unchanged from Phase 1 apart from *which* uid gets cached
  (your own, plus whichever crew member is currently "spotlighted").
- **The widget's post-proof button is a deep link, not a true
  interactive action**: pre-iOS 17 widgets can't run app logic in
  place, so tapping the camera icon opens the app via
  `proof://capture?crewId=...` (handled in `ProofApp.onOpenURL`,
  routed through `SessionViewModel.pendingCaptureCrewId`) and drops
  straight into that crew's capture sheet — not literally "without
  opening the app," but the closest realistic equivalent at this
  deployment target.
- **Push notifications** are still the one place the app needs
  server-side code (`functions/index.js`): `notifyPartnersOnProof` now
  triggers on `crews/{crewId}/feed/{itemId}` (filtered to
  `type == "proof"`) instead of the old per-resolution proof path, but
  otherwise works the same — looks up the poster's accepted partners,
  sends via FCM to whoever has a `pushToken` saved.
  `PushNotificationService` (client) requests permission and keeps
  that token current — declining the permission prompt just means
  silently never getting nudged. `project.yml` sets `aps-environment:
  development`; switch it to `production` before an App Store/
  TestFlight build or push silently won't work for anyone outside
  Xcode.
- **Creator gating**: `UserProfile.isCreator` can never be set by the
  user themselves — firestore.rules only allows an update where that
  field is unchanged from its current value, so the very first creator
  has to be flipped on directly in the Firebase console (see Setup,
  step 1). Everything Creator Tools writes (rewards, `boosted: true`
  crews) is re-checked server-side against this flag, not just hidden
  behind a UI row.

## Known gaps

- No unit or UI tests yet.
- Crew chat's message field is visually present but disabled — posting
  a plain text message to a crew isn't wired up yet, only proof photos
  are. The data model (`CrewFeedItem.type == .message`) already
  supports it; it's a UI-only gap.
- `doneToday` on a crew member doc is set `true` by `StreakEngine` but
  nothing ever flips it back to `false` at midnight — needs a
  scheduled Cloud Function (or computing "done today" at read time
  from `lastProofDate` instead of trusting the stored flag) before
  this ships.
- No image compression/resizing beyond JPEG quality — full-resolution
  camera photos upload as-is.
- No widget-side crew picker — see the Architecture note above.
- No push notification when someone *sends a partner request* — only
  when an existing partner posts a proof. A request still only
  surfaces next time the recipient opens the Friends tab.
- No tap-through routing on the push notification yet — tapping it
  just opens the app to wherever it was left. Would need a
  notification `userInfo` payload plus navigation state, same shape as
  the widget's `proof://` deep link already sets up.
- No UI to revoke an accepted partnership once granted, or to leave a
  crew, or for a crew owner to delete/edit an existing crew's
  name/vibe/icon after creation (only event/challenge and Creator
  Tools' boosted-crew removal have delete/edit paths right now).
- Local's "For" picker (Create Event/Challenge) only ever offers the
  user's own private crews plus "Local" — it doesn't let you target a
  public crew you've joined but don't own.
- No content moderation on the public Feed or crew chats — anyone
  opted in can post anything; worth a report/block mechanism before
  a real public launch.

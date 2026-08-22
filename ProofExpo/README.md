# Proof — Expo Go preview

The same Phase 1 app as `../Proof` (the native SwiftUI build), rebuilt
in React Native so it can actually run in **Expo Go** — no Xcode, no
Mac, no Firebase project needed to try it.

## What's different from the native build

- **No backend.** Everything (resolutions, proofs, friends, partner
  requests) lives in memory for the session — see
  `src/state/AppState.tsx`. Close the app and it resets to the seed
  data in `src/data/mockData.ts`. Wiring up real Firebase later means
  replacing the functions in that one file; the screens don't need to
  change.
- **Sign-in is simulated.** Tapping "Continue with Apple/Google" just
  flips a boolean — there's no real OAuth flow.
- **No home screen widget.** WidgetKit-style widgets can't run inside
  Expo Go (they need a native build). The Profile tab shows a static
  preview of what the real widget looks like instead — see
  `../Proof/ProofWidget` for the actual implementation.

## Run it

You need a machine with [Node.js](https://nodejs.org) installed (this
does **not** need to be a Mac — Windows/Linux work fine, since there's
no Xcode step here).

```
cd ProofExpo
npm install
npx expo start
```

That prints a QR code in the terminal. Open the **Expo Go** app on
your iPad/iPhone (App Store) and scan it — either through Expo Go's
own scanner, or through the Camera app, which will offer to open it in
Expo Go. Your device and the machine running `expo start` need to be
on the **same Wi-Fi network** for the default (LAN) connection mode.

If they're not on the same network — e.g. you're running this from a
cloud dev environment — pass `--tunnel` instead:

```
npx expo start --tunnel
```

(This installs `@expo/ngrok` the first time it runs. Tunnel mode is
slower and depends on your network allowing the tunnel connection
through — if it hangs on "tunnel took too long to connect", that
environment's network doesn't allow it and you'll need LAN mode from
a machine that shares Wi-Fi with your device instead.)

## What to try

- **Today tab**: tap an incomplete mission → capture a proof photo
  (camera or library — both work in Expo Go) → watch the streak and
  ✅ update.
- **Friends tab**: Marco is already an accepted accountability
  partner — tap "Partners" on his row to browse his resolutions and
  proof photo, read-only. Léa isn't a partner yet — tap "Share" to
  send her a request (it'll sit at "Requested", since nobody's there
  to accept it in this offline build). Sam already sent *you* a
  request — accept or decline it in the "Proof-sharing requests"
  section at the top.
- **Profile tab**: edit your name, and scroll down to see the widget
  preview.

## Project layout

```
App.tsx                     entry point: providers + auth gate
src/
  types/                    shared TS types (Resolution, Friend, ...)
  data/mockData.ts           seed data + todayString() helper
  state/AppState.tsx          in-memory "backend" (Context + hooks)
  navigation/                 React Navigation stack + tabs
  screens/                    one file per screen
  components/                 shared UI (MissionRow, PhotoTile, ...)
```

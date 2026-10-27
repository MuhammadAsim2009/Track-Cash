# TrackCash

Offline-first personal finance app built with **Flutter**, **SQLite** and **Firebase**.
Track money across Cash, Savings and Easypaisa/JazzCash, log daily spending, set a monthly budget, and manage udhaar (who you owe / who owes you) with due-date reminders.

## Features
- Email + password registration (multi-user, private data)
- Wallets with balances and transfers (with history)
- Income and expense tracking with default + custom categories
- Flexible monthly budget (total, per category, or both)
- Udhaar tracking with reminders
- Dark / light theme
- Works offline, syncs to Firebase

## Tech stack
Flutter · Dart · SQLite (sqflite) · Firebase Auth · Cloud Firestore · Riverpod · flutter_local_notifications · fl_chart

## Setup
1. Install Flutter (stable) and Android Studio / VS Code.
2. Clone the repo and run `flutter pub get`.
3. Create a Firebase project, add an Android app, download `google-services.json` into `android/app/`.
4. Enable **Authentication → Email/Password** and create a **Firestore** database.
5. Deploy the rules from `Security-Access.md` (`firestore.rules`).
6. Run `flutter run`.

## Docs
`PRD.md` · `Architecture.md` · `rules.md` · `phases.md` · `design.md` · `memory.md` · `Security-Access.md`

## Status
See `memory.md` for current progress.

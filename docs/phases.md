# Build Phases

Build in order. Finish and test each phase before the next. Update `memory.md` after each.

**Approach: UI first (dummy data) → SQLite → Firebase.**

## Phase 0 — Setup
Flutter project, folder structure, packages, git repo, theme skeleton (light/dark).

## Phase 1 — Complete UI (dummy data)
Build every screen, dialog and state with proper design, using fake data from in-memory "fake repositories":
- Auth screens: login, register, forgot password
- Dashboard (total balance, wallet cards, budget progress, upcoming udhaar)
- Transactions list + filters, add/edit income and expense
- Transfers: new transfer + history
- Budget: set budget (total / per category / both), progress view
- Udhaar: give/take lists, add/edit/settle, due date picker
- Categories: list, add, edit, hide
- Settings/More: theme switcher, logout
- Dialogs: confirm delete, validation errors, success messages
- Empty, loading and error states for every list
- Navigation, dark + light theme, all form validation

Rule: screens talk only to repository interfaces (not to dummy data directly), so Phase 2 only swaps the implementation.

## Phase 2 — SQLite (make it dynamic)
Database + migrations, DAOs, real repositories replacing the fake ones, default wallets and categories, balance and budget calculations, transfers, soft delete, udhaar + local due-date reminders. Use a temporary local user id until real auth is connected.

## Phase 3 — Firebase Auth
Real register, login, logout, password reset, auth gate. Replace the temporary user id with the Firebase uid; keep data separated per user; clear local data on logout.

## Phase 4 — Firebase sync
Firestore structure, security rules, push/pull sync, restore on new device, offline testing.

## Phase 5 — Polish + testing
Edge cases from `Security-Access.md`, test with two accounts (data isolation), offline/online scenarios, app icon and name, release APK, GitHub push with README.

# Rules

## Use
- Flutter stable, Dart null safety, Material 3.
- Riverpod for state; repository pattern (UI never talks to SQLite/Firestore directly).
- `sqflite` for local DB, with versioned migrations.
- UUIDs for all ids (safe for offline creation + sync).
- Integer money (rupees). Format only in the UI with `intl`.
- One feature = one folder under `features/`.
- Small widgets, reusable components in `widgets/`.
- `flutter analyze` must pass with no warnings before each commit.

## Avoid
- Floating-point (`double`) for money.
- Hard-deleting rows (use `is_deleted`).
- Putting business logic inside widgets.
- Hardcoded colors/text styles (use the theme).
- Extra features not in `PRD.md` (no feature creep — this is why v1 was dropped).
- Heavy/unneeded packages. Ask before adding any new dependency.
- Storing passwords or tokens manually (Firebase Auth handles them).

## Error handling
- All repository methods return success or a typed `AppException` (auth, network, validation, database, sync).
- Show friendly messages (snackbar/dialog), never raw exception text.
- Never crash on network failure: queue changes locally and retry sync.
- Validate input before saving: amount > 0, wallet selected, name not empty, due date valid.
- Log errors with `debugPrint` in dev only.

## Money rules
- An expense cannot be saved without a wallet; warn (don't block) if it makes a wallet negative.
- Transfers need two different wallets and an amount > 0.
- Transfers never affect income/expense totals or the budget.

## AI boundaries (for AI-assisted coding)
- AI must follow `PRD.md`, `Architecture.md` and this file; no scope changes without approval.
- AI must not add dependencies, change DB schema, or change security rules without saying so first.
- AI must not delete or rewrite working files unless asked.
- Build one phase at a time (see `phases.md`) and update `memory.md` after each.
- No secrets (API keys, `google-services.json` contents) pasted into chat or committed to public repos.

## UI-first rule
- Phase 1 screens use repository **interfaces** with fake in-memory implementations.
- Do not put dummy data inside widgets. Real SQLite repositories replace the fakes in Phase 2 without changing the UI code.

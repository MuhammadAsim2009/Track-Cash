# Memory — Project Progress

## Completed
- Requirements clarified.
- Project docs created (PRD, README, Architecture, rules, phases, design, Security-Access).
- Phase 0 Setup & Phase 1 Foundation built:
  - Added required dependencies to pubspec.yaml: `flutter_riverpod`, `google_fonts`, `intl`, `uuid`, `shared_preferences`, `fl_chart`.
  - Core theme: `AppColors` & `AppColorsExtension` (custom green scheme, income/expense/warning/border tokens) and `AppTheme` (light and dark themes using Poppins and Inter from Google Fonts).
  - Theme switching & persistence: `ThemeModeNotifier` & `themeModeProvider` stored in `SharedPreferences`.
  - Utils: `CurrencyFormatter` (strict PKR integer rupee formatting `Rs 12,500`) and `DateFormatter` (date/time/monthKey helpers).
  - Domain exceptions: `AppException` hierarchy (`ValidationException`, `DatabaseException`, etc.).
  - Plain Dart models: `Wallet`, `AppCategory`, `TransactionEntry`, `Transfer`, `Budget`, `Udhaar` with UUIDs, integer currency, `copyWith`, and value equality.
  - Repository interfaces & fake in-memory implementations with realistic Pakistani seed data (`FakeWalletsRepository`, `FakeCategoriesRepository`, `FakeTransactionsRepository`, `FakeTransfersRepository`, `FakeBudgetsRepository`, `FakeUdhaarRepository`).
  - Riverpod repository and reactive stream providers.
- Phase 1 Complete UI (dummy data):
  - Shared UI Components (`lib/widgets/`): `EmptyStateView`, `ErrorStateView`, `showConfirmDialog`, `MoneyInputField`, `WalletCard`, `TransactionTile`, `BudgetProgressBar`, `UdhaarTile`.
  - Auth Flow (`lib/features/auth/`): `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`, `OpeningBalancesScreen`, and `authStateProvider` with complete validation and session transitions.
  - Dashboard (`lib/features/dashboard/`): Total balance (with privacy hide/show toggle), quick action buttons (Income, Expense, Transfer), live wallet cards with details modal, monthly budget progress card, upcoming udhaar list, and recent transactions.
  - Transactions (`lib/features/transactions/`): Multi-filter header (Month, Type, Wallet, Category), Income/Expense summary bar, date-grouped list, long-press delete with confirmation, and `AddEditTransactionScreen` with negative balance warnings.
  - Transfers (`lib/features/transfers/`): `AddTransferScreen` with validation (From != To, amount > 0) and `TransfersScreen` (history, from/to cards, delete).
  - Budget (`lib/features/budget/`): `BudgetScreen` with month navigation, total budget progress bar, per-category progress breakdown, "Copy Last Month" feature, and `SetBudgetScreen` supporting Total, Per-category, or Both modes.
  - Udhaar (`lib/features/udhaar/`): `UdhaarScreen` with "I have to give" & "I have to take" tabs, net debt/credit summary header, due-date chips with overdue alerts, settle toggle, delete confirmation, and `AddEditUdhaarScreen` with date presets.
  - Categories (`lib/features/categories/`): `CategoriesScreen` with Expense and Income tabs, default vs custom chips, hide/unhide toggle, icon and color picker dialogs, and deletion for custom categories.
  - Custom Floating Notched Bottom Bar & Navigation Shell (`lib/widgets/floating_nav_bar.dart`, `lib/widgets/tab_screen_wrapper.dart`, `lib/features/home/`):
    - Replaced default BottomNavigationBar/NavigationBar with a custom floating notched bar: `Home | Transactions | (+) | Budget | Udhaar`.
    - Pure Flutter `CustomPainter` with smooth `cubicTo` bezier curves (no third-party packages, no `BottomAppBar`/`CircularNotchedRectangle`).
    - Margins: 16 horizontal, 12 bottom + system safe area, 28 corner radius.
    - Theme styling: Light mode uses white surface with soft shadow; Dark mode uses `#1E293B` surface with 1px `#334155` border (no shadow).
    - Center 56px circular green `+` button in notch, slightly raised, triggers Add Transaction (Expense by default with Income toggle).
    - Removed old floating action buttons from Home and Transactions screens.
    - Centralized `TabScreenWrapper` providing 100px + safe area bottom padding to all tab screens so list content is never obscured.
    - Tab selection state managed cleanly in Riverpod (`navigationIndexProvider`) with state preserved via `IndexedStack`.
    - Smooth 200ms selection transition for tab icons and visible labels.
  - `flutter analyze` passing with 0 issues / 0 warnings.
- Phase 2 SQLite Implementation (Local Dynamic Database):
  - Added dependencies `sqflite`, `path`, and `sqflite_common_ffi` (for desktop testing support).
  - Implemented `toMap()` and `fromMap()` serialization across all domain models (`Wallet`, `AppCategory`, `TransactionEntry`, `Transfer`, `Budget`, `Udhaar`).
  - Created [`AppDatabase`](file:///e:/track_cash/lib/data/local/app_database.dart) singleton in `lib/data/local/` with SQLite tables, schema indexes, and initial data seeding.
  - Built production SQLite repositories with reactive broadcast streams and live SQL balance aggregations:
    - [`SqliteWalletsRepository`](file:///e:/track_cash/lib/data/repositories/sqlite/sqlite_wallets_repository.dart)
    - [`SqliteCategoriesRepository`](file:///e:/track_cash/lib/data/repositories/sqlite/sqlite_categories_repository.dart)
    - [`SqliteTransactionsRepository`](file:///e:/track_cash/lib/data/repositories/sqlite/sqlite_transactions_repository.dart)
    - [`SqliteTransfersRepository`](file:///e:/track_cash/lib/data/repositories/sqlite/sqlite_transfers_repository.dart)
    - [`SqliteBudgetsRepository`](file:///e:/track_cash/lib/data/repositories/sqlite/sqlite_budgets_repository.dart)
    - [`SqliteUdhaarRepository`](file:///e:/track_cash/lib/data/repositories/sqlite/sqlite_udhaar_repository.dart)
  - Swapped Riverpod repository providers in [`repository_providers.dart`](file:///e:/track_cash/lib/data/repositories/repository_providers.dart) to the SQLite implementations.
  - App startup in [`main.dart`](file:///e:/track_cash/lib/main.dart) initializes `AppDatabase` before rendering.
  - All screens are now dynamic with full CRUD and reactive state propagation via SQLite.
  - `flutter analyze` passing with 0 issues / 0 warnings.

- Phase 3 — Firebase Auth:
  - Added `.gitignore` entries for `lib/firebase_options.dart` and Google Services credentials.
  - Added dependencies `firebase_core` and `firebase_auth`.
  - Initialized Firebase in `main.dart` with `DefaultFirebaseOptions.currentPlatform`.
  - Replaced fake auth notifier with real `FirebaseAuthNotifier` tracking `FirebaseAuth.instance.authStateChanges()`.
  - Connected real registration (`createUserWithEmailAndPassword`), login (`signInWithEmailAndPassword`), password reset (`sendPasswordResetEmail`), and logout (`signOut`).
  - Added `currentUserIdProvider` and injected it across all SQLite repositories (`SqliteWalletsRepository`, `SqliteTransactionsRepository`, `SqliteTransfersRepository`, `SqliteBudgetsRepository`, `SqliteUdhaarRepository`, `SqliteCategoriesRepository`) to enforce strict user data isolation.
  - Implemented automatic initial wallet and category seeding per user ID upon registration/login.
  - Implemented local SQLite wipe on logout to prevent cross-user data leakage on shared devices.
  - Updated all feature creation screens (`add_edit_transaction_screen`, `add_transfer_screen`, `add_edit_udhaar_screen`, `categories_screen`, `set_budget_screen`) to use `currentUserIdProvider`.
  - `flutter analyze` passing with 0 issues / 0 warnings.

## In progress
- Phase 3 Complete. Ready for Phase 4: Firebase Sync (Firestore).

## Next step
- Phase 4 — Firebase sync:
  - Add `cloud_firestore` dependency.
  - Design Firestore schema under `users/{uid}/...`.
  - Implement push/pull synchronization between local SQLite and Firestore.
  - Add offline detection, sync status flags, and conflict resolution (last write wins by `updated_at`).

## Decisions
- Build order: full UI with dummy data → SQLite → Firebase Auth → Firebase sync.
- Flutter + SQLite (local source of truth) + Firebase Auth/Firestore (backup/sync).
- Email + password only. Multi-user, no admin. PKR only.
- Strict integer rupees for money; no floating-point.
- Abstract repository interfaces exposed via Riverpod providers to allow zero-UI-change swap to SQLite in Phase 2.

## Notes
- Update this file after every phase.

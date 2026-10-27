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
  - Navigation & App Shell (`lib/features/home/` & `lib/app.dart`): Auth gate, 4-tab bottom navigation bar, FAB on Home and Transactions, and "More" menu (Categories, Transfers, Theme selector dialog, Logout).
  - `flutter analyze` passing with 0 issues / 0 warnings.

## In progress
- Phase 1 Complete. Ready for Phase 2: SQLite database implementation.

## Next step
- Phase 2 — SQLite (make it dynamic):
  - Add `sqflite` and `path` packages.
  - Create `lib/data/local/` (database helper, schema version 1, table migrations, DAOs).
  - Implement real SQLite repositories implementing the exact same repository interfaces (`WalletsRepository`, `CategoriesRepository`, `TransactionsRepository`, etc.).
  - Default wallets and default categories seeded on first database creation.
  - Dynamic balance and budget calculations in SQL.
  - Soft-delete handling (`is_deleted = 1`).
  - Udhaar local notifications for due date reminders (`flutter_local_notifications` + `timezone`).
  - Swap Riverpod provider implementations from fake repositories to SQLite repositories.

## Decisions
- Build order: full UI with dummy data → SQLite → Firebase Auth → Firebase sync.
- Flutter + SQLite (local source of truth) + Firebase Auth/Firestore (backup/sync).
- Email + password only. Multi-user, no admin. PKR only.
- Strict integer rupees for money; no floating-point.
- Abstract repository interfaces exposed via Riverpod providers to allow zero-UI-change swap to SQLite in Phase 2.

## Notes
- Update this file after every phase.

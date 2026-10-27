# Architecture

## Tech stack
| Layer | Choice |
|---|---|
| UI | Flutter (Material 3) |
| State management | Riverpod |
| Local DB | SQLite via `sqflite` (source of truth) |
| Auth | Firebase Auth (email + password) |
| Cloud backup/sync | Cloud Firestore |
| Reminders | `flutter_local_notifications` + `timezone` |
| Charts | `fl_chart` |
| Utilities | `intl`, `uuid`, `shared_preferences` (theme) |

## Core idea: offline-first
SQLite is the source of truth. Every write goes to SQLite first, marked `synced = 0`. A sync service pushes unsynced rows to Firestore when online and pulls newer remote rows. Firebase Auth identifies the user; the `uid` scopes all data.

## App flow
```
Splash → (logged in?) ── no ──► Login / Register / Reset password
                │
               yes
                ▼
        Home (bottom nav)
        ├─ Dashboard: total balance, wallets, month budget, upcoming udhaar
        ├─ Transactions: list + filters, add income/expense
        ├─ Budget: set/view monthly budget
        ├─ Udhaar: I have to give / I have to take
        └─ More: Transfers & history, Categories, Theme, Logout
```

## Folder structure
```
lib/
├─ main.dart
├─ app.dart                  # MaterialApp, theme, routes
├─ core/
│  ├─ constants/             # default categories, wallet names
│  ├─ theme/                 # light/dark themes
│  ├─ utils/                 # money formatter, date helpers, validators
│  └─ errors/                # AppException types
├─ data/
│  ├─ local/                 # database.dart, migrations, DAOs
│  ├─ remote/                # firestore_service.dart, auth_service.dart
│  ├─ models/                # wallet, transaction, transfer, category, budget, udhaar
│  └─ repositories/          # combine local + sync
├─ services/
│  ├─ sync_service.dart
│  └─ notification_service.dart
├─ features/
│  ├─ auth/
│  ├─ dashboard/
│  ├─ wallets/
│  ├─ transactions/
│  ├─ transfers/
│  ├─ budget/
│  ├─ udhaar/
│  ├─ categories/
│  └─ settings/
└─ widgets/                  # shared UI components
```

## Local database (SQLite)
All tables include: `id` (UUID text), `user_id`, `created_at`, `updated_at`, `is_deleted` (0/1), `synced` (0/1).
Money is stored as **integer rupees** (no doubles).

- **wallets**: name, type (cash/savings/mobile_wallet), opening_balance
- **categories**: name, type (income/expense), icon, color, is_default, is_hidden
- **transactions**: wallet_id, category_id, type (income/expense), amount, note, date
- **transfers**: from_wallet_id, to_wallet_id, amount, note, date
- **budgets**: month (YYYY-MM), mode (total/category), category_id (nullable), amount
- **udhaar**: person_name, amount, direction (give/take), due_date, status (pending/settled), note, notification_id

Wallet balance is computed: opening + income − expenses + transfers in − transfers out (ignoring `is_deleted = 1`).

## Firestore layout
```
users/{uid}
users/{uid}/wallets/{id}
users/{uid}/categories/{id}
users/{uid}/transactions/{id}
users/{uid}/transfers/{id}
users/{uid}/budgets/{id}
users/{uid}/udhaar/{id}
```
Conflict rule: **last write wins** by `updated_at`.

## Sync logic
1. On app start / network back / after a write: push rows where `synced = 0`.
2. Pull remote docs with `updated_at` greater than the last pull time (stored locally).
3. Soft-deleted rows sync as `is_deleted = true` (never hard-deleted remotely in MVP).
4. On first login on a new phone: full pull.
5. On logout: clear local DB for that user (data is safe in Firebase), cancel notifications.

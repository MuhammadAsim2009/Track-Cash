# Security & Access

## Authentication
- Firebase Auth, **email + password** only.
- Minimum password length 8. Password reset via email.
- Session persisted by Firebase; auth gate checks it at startup.
- Email verification: optional in MVP (recommended later).

## User roles & permissions
| Role | Access |
|---|---|
| User | Full read/write on **own** data only |
| Admin | None (no admin role in MVP) |

## Row-level security (Firestore rules)
Every document lives under `users/{uid}/...`. A user can only access their own path.
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```
Locally, every SQLite query filters by `user_id = currentUid`. The local DB is cleared on logout.

## Error handling per failure type
| Failure | Behavior |
|---|---|
| Wrong email/password | "Email or password is incorrect." No hint which one |
| Email already registered | "This email is already in use. Try logging in." |
| Weak password / invalid email | Inline field error before submitting |
| No internet (auth) | "No internet connection. Please try again." |
| No internet (data) | Save locally, mark unsynced, sync later; no error shown |
| Too many attempts | Show Firebase's temporary-block message, disable button briefly |
| Firestore permission denied | Stop sync, show "Sync problem, please log in again", keep local data |
| Sync conflict | Last write wins by `updated_at` |
| SQLite write failure | Show "Could not save. Try again." and keep form data |
| Notification permission denied | Explain why reminders need it, link to settings |
| Session expired | Redirect to login, keep unsynced local data until re-login |

## Edge cases to handle before launch
- Two different users logging in on the same phone (local data must not mix).
- User logs out with unsynced data (warn or sync first).
- Phone clock/time zone change (due dates and monthly budgets).
- Deleting a wallet/category that has transactions (block, or reassign; never orphan data).
- Negative wallet balance (warn, allow).
- Very large amounts / zero / negative input (validate).
- Month rollover (budget for new month empty; offer "copy last month").
- Overdue udhaar (show clearly, keep reminding once).
- App reinstall: data restored from Firebase after login.
- Reminder rescheduling after phone reboot and after editing/settling udhaar.
- Account deletion: delete Firestore data and auth account (add before public release).
- Firebase config files kept out of public GitHub if sensitive; rules tested with 2 accounts.

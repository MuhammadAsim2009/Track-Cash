# App Flow

How a user moves through the app, screen by screen.

## 1. App start
```
Launch → Splash
   ├─ Not logged in → Login
   └─ Logged in     → Home (Dashboard)
```
First time after registering: a short **setup screen** to enter opening balances for Cash, Savings and Easypaisa/JazzCash (can skip, default 0), then Home.

## 2. Authentication flow
```
Login ──► Home
  ├─ "Create account" ──► Register ──► Opening balances ──► Home
  └─ "Forgot password" ──► Enter email ──► "Reset email sent" ──► Login
```
- Register: name, email, password, confirm password.
- Errors shown inline (wrong password, email in use, weak password, no internet).
- Logout (More → Logout) returns to Login.

## 3. Main navigation
Bottom bar with 4 tabs; "More" opens from the app bar menu.
```
Home | Transactions | Budget | Udhaar          ⋮ More
```
A floating **+** button on Home and Transactions opens quick add.

## 4. Screens and actions

### Home (Dashboard)
- Total balance
- Wallet cards: Cash, Savings, Easypaisa/JazzCash (tap → wallet details)
- This month: spent vs budget progress bar
- Upcoming udhaar (next due items)
- Recent transactions (last 5) → "See all" → Transactions
- Buttons: **Add Income**, **Add Expense**, **Transfer**

### Add / Edit Transaction
```
+ button → choose Income or Expense
   → amount → wallet → category → date → note (optional) → Save
```
- Validation: amount > 0, wallet and category required.
- After save: back to previous screen, balance and budget update, success snackbar.
- Edit/delete from the transaction tile (delete asks for confirmation).

### Transactions
- List grouped by date
- Filters: month, wallet, category, income/expense
- Tap a tile → edit; swipe/long-press → delete

### Transfer
```
Home / More → Transfer → from wallet → to wallet → amount → date → note → Save
```
- From and to must be different; amount > 0.
- **Transfer History** (More → Transfers): list of past transfers.

### Budget
```
Budget tab
 ├─ No budget set → "Set budget" → choose mode:
 │     • Total monthly budget
 │     • Per-category budget
 │     • Both
 │   → enter amounts → Save
 └─ Budget set → progress (spent / remaining / days left)
       • per-category bars (if used)
       • Edit budget
```
- Warning at 80% and when exceeded.
- New month: prompt "Copy last month's budget?"

### Udhaar
```
Udhaar tab
 ├─ Tab 1: I have to give
 └─ Tab 2: I have to take
+ button → person name → amount → give/take → due date → note → Save
```
- Tile shows name, amount, due date (overdue in red).
- Tap → details → **Mark as settled** / Edit / Delete.
- Reminder notification on due date and 1 day before.
- Tapping the notification opens that udhaar entry.

### More
- Categories → list, add, edit, hide
- Transfers → history
- Theme → Light / Dark
- Logout

## 5. Daily user journeys

**Log an expense:** Home → + → Expense → amount, wallet, category → Save → dashboard updates.

**Move money:** Home → Transfer → Easypaisa → Cash → amount → Save → both wallet balances update.

**Lend money:** Udhaar → + → name, amount, "I have to take", due date → Save → reminder scheduled.

**Get repaid:** Udhaar → tap entry → Mark as settled → reminder cancelled. (Optionally add the money as income to a wallet.)

**Start a new month:** Budget → "Copy last month's budget?" → Yes / set new.

## 6. Offline and sync behavior (user's view)
- Everything works with no internet.
- A small sync indicator (synced / pending) appears in More or the app bar.
- On a new phone: Login → data restored automatically.

## 7. Empty and error states
- No transactions: "No transactions yet. Tap + to add one."
- No budget: "Set a monthly budget to track spending."
- No udhaar: "No pending udhaar."
- Load/sync failure: message with a Retry button.

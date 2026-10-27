# PRD — TrackCash

## 1. What we are building
A simple personal-finance app (Flutter) where a user records how much money they have in different places, logs daily income and spending, sets a monthly budget, and tracks udhaar (money to give / take). Multiple users can register; each user only sees their own data.

## 2. Why (problem)
The previous version (React Native) had too many features, a weak UI, and did not match real daily needs. This rebuild is small, clean, and focused on: *"Where is my money, where did it go, and who owes whom?"*

## 3. Target users
- Students and young earners in Pakistan with money split across cash, savings and mobile wallets (Easypaisa / JazzCash).
- Anyone who lends/borrows money informally and forgets due dates.

## 4. Core features (MVP)
### 4.1 Accounts / users
- Register and log in with **email + password** (Firebase Auth).
- Many users supported; data is private per user.
- Logout, password reset by email.

### 4.2 Money places (wallets)
- Three default wallets: **Cash in hand**, **Savings**, **Easypaisa / JazzCash**.
- Set an opening balance for each.
- Current balance = opening balance + income − expenses ± transfers.
- Total balance shown on the home screen.

### 4.3 Income and expenses
- Add income (e.g. project earning, pocket money) into a chosen wallet.
- Add expense from a chosen wallet with category, amount, date, optional note.
- Edit and delete entries (soft delete so sync stays safe).
- Filter/list by day, month, wallet, category.

### 4.4 Transfers
- Move money between wallets (e.g. Easypaisa → Cash).
- **Transfer history** screen (from, to, amount, date, note).
- Transfers do not count as income or expense.

### 4.5 Categories
- Default categories shipped with the app (Food, Transport, Bills, Shopping, Education, Health, Entertainment, Other; income: Project Earning, Pocket Money, Other).
- Users can add, rename and hide their own categories.

### 4.6 Monthly budget
- User chooses how to set it: **one total monthly budget**, **per-category budgets**, or **both**.
- Progress bar: spent vs budget, remaining amount, days left.
- Warning at 80% and when exceeded.
- Option to copy last month's budget to a new month.

### 4.7 Udhaar (lend / borrow)
- Two lists: **I have to give** and **I have to take**.
- Fields: person name, amount, due date, optional note, status (pending / settled).
- **Due-date reminder** via local notification (on due date, plus 1 day before).
- Mark as settled (simple; no partial payments in MVP).

### 4.8 Theme
- Dark and light themes, switchable by the user, remembered between launches.

### 4.9 Offline + backup
- Works fully offline using SQLite.
- Syncs to Firebase when online; data restored on a new phone after login.

## 5. Out of scope (for now)
Partial udhaar payments, multi-currency, shared/family budgets, admin panel, bank/SMS auto-import, Google sign-in, export to Excel/PDF.

## 6. Currency & locale
PKR only. Amounts stored as whole integers (no floating-point money).

## 7. Success criteria
- Add an expense in 3 taps or fewer.
- Home screen shows total balance, per-wallet balance, month spending vs budget, and upcoming udhaar.
- No data visible across users.
- App usable with no internet.

## 8. Open questions
- Whether to add Google sign-in later.

# 💸 TrackCash

**TrackCash** is a personal finance app to track your wallets, monthly budget and udhaar. Built with Flutter, SQLite and Firebase.

[![GitHub repo](https://img.shields.io/badge/GitHub-Track--Cash-blue?logo=github)](https://github.com/MuhammadAsim2009/Track-Cash)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![SQLite](https://img.shields.io/badge/SQLite-003B57?logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)

Designed for speed, clarity, and daily reliability, TrackCash operates offline-first using SQLite and syncs seamlessly with Firebase Firestore when connected. It lets you manage multiple wallets, set category budgets, record debts and loans (Udhaar) with partial settlements, transfer money between accounts, and compute a dynamic daily allowance.

---

## ✨ Features

- 📱 **Multi-Wallet Management**
  - Track Cash, Savings Accounts, and Mobile Wallets (e.g., EasyPaisa, JazzCash).
  - Customize opening balances and toggle wallets in or out of daily expense calculations.
  - Safe soft-deletion with balance protection (wallets can only be deleted when balance is 0; past transaction history retains wallet names).

- 📊 **Smart Dashboard & Daily Allowance**
  - Instant overview of total balance, monthly expenditures, and budget consumption.
  - Dynamic daily allowance calculation based on remaining days and remaining budget.
  - Quick-action shortcuts for rapid expense/income entries, transfers, and udhaar.

- 🧾 **Comprehensive Transaction Tracking**
  - Income and expense logging with multi-wallet support and categories.
  - Interactive monthly navigation, date filtering, and category breakdowns.
  - Clean transaction grouping by date with search and filter controls.

- 🤝 **Udhaar (Debt & Loan) Management**
  - Track money you owe (**To Pay / Dena Hai**) and money owed to you (**To Receive / Lena Hai**).
  - Due date tracking with visual status indicators (pending, due soon, overdue).
  - **Partial Payments**: Record installments and settlements with designated wallets until the balance is completely settled.

- 🔄 **Account-to-Account Transfers**
  - Transfer funds seamlessly between your cash, bank, and digital wallets without skewing income/expense analytics.

- 🎯 **Monthly Category Budgets**
  - Set spending thresholds for individual categories (Food, Utilities, Travel, Shopping, etc.).
  - Real-time progress bars with warning states (e.g., 80% caution, 100% exceeded).

- 👤 **Profile & Security**
  - Update user profile details, display name, and securely change passwords.
  - Firebase authentication state handling.

- ⚡ **Offline-First & Cloud Sync**
  - Instant local reads/writes backed by SQLite (`sqflite`).
  - Background two-way synchronization with Firebase Cloud Firestore.
  - Full functionality without active internet connectivity.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (Dart 3)
- **State Management**: [Riverpod](https://riverpod.dev)
- **Local Storage**: [SQLite via sqflite](https://pub.dev/packages/sqflite) (Offline-first repository pattern)
- **Cloud Backend**: [Firebase Cloud Firestore](https://firebase.google.com/products/firestore) & [Firebase Auth](https://firebase.google.com/products/auth)
- **Design System**: Material 3 with customizable theme tokens and dark/light support

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.3.0`
- Android Studio / VS Code with Flutter extension
- Firebase project configured with Firestore & Authentication

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MuhammadAsim2009/Track-Cash.git
   cd Track-Cash
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup:**
   Ensure you have configured Firebase using the FlutterFire CLI or placed your `google-services.json` inside `android/app/`.
   ```bash
   flutterfire configure
   ```

4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```
lib/
├── core/                 # App constants, theme, currency/date formatters, toasts
├── data/
│   ├── database/         # SQLite database helper & schema definitions
│   ├── models/           # Domain data models (Wallet, Transaction, Udhaar, Budget, etc.)
│   ├── repositories/     # Repository interfaces, SQLite & Firestore implementations
│   └── sync/             # Offline-first background synchronization engine
├── features/
│   ├── auth/             # Login, signup, password reset
│   ├── budget/           # Monthly category budget management
│   ├── dashboard/        # Home screen, summary metrics, daily allowance
│   ├── home/             # Main navigation container
│   ├── profile/          # Profile view, password changes, user preferences
│   ├── splash/           # Splash & authentication guard
│   ├── transactions/     # Add, edit, list, and filter transactions
│   ├── transfers/        # Wallet-to-wallet transfer flows & history
│   ├── udhaar/           # Debt/credit tracking & partial settlement dialogs
│   └── wallets/          # Wallet management & balance verification
└── widgets/              # Reusable UI widgets (cards, tiles, dialogs, empty states)
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

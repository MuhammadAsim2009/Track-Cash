import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction_entry.dart';
import '../models/transfer.dart';
import '../models/udhaar.dart';
import '../models/wallet.dart';

const String kDemoUserId = 'user_trackcash_demo';

// Wallet IDs
const String kWalletCashId = 'wallet_cash_01';
const String kWalletSavingsId = 'wallet_savings_02';
const String kWalletMobileId = 'wallet_mobile_03';

// Category IDs
const String kCatFoodId = 'cat_food';
const String kCatTransportId = 'cat_transport';
const String kCatBillsId = 'cat_bills';
const String kCatShoppingId = 'cat_shopping';
const String kCatEducationId = 'cat_education';
const String kCatHealthId = 'cat_health';
const String kCatEntertainmentId = 'cat_entertainment';
const String kCatExpenseOtherId = 'cat_expense_other';

const String kCatProjectEarningId = 'cat_project_earning';
const String kCatPocketMoneyId = 'cat_pocket_money';
const String kCatIncomeOtherId = 'cat_income_other';

/// Realistic initial seed data for Phase 1 UI demo.
class FakeSeedData {
  FakeSeedData._();

  static final DateTime _now = DateTime.now();

  static List<Wallet> get initialWallets => [
        Wallet(
          id: kWalletCashId,
          userId: kDemoUserId,
          name: 'Cash in hand',
          type: WalletType.cash,
          openingBalance: 8500,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        Wallet(
          id: kWalletSavingsId,
          userId: kDemoUserId,
          name: 'Savings',
          type: WalletType.savings,
          openingBalance: 65000,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        Wallet(
          id: kWalletMobileId,
          userId: kDemoUserId,
          name: 'Easypaisa / JazzCash',
          type: WalletType.mobileWallet,
          openingBalance: 14200,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
      ];

  static List<AppCategory> get initialCategories => [
        // Expense categories
        AppCategory(
          id: kCatFoodId,
          userId: kDemoUserId,
          name: 'Food',
          type: CategoryType.expense,
          icon: 'restaurant',
          color: 0xFFEF4444, // Red-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatTransportId,
          userId: kDemoUserId,
          name: 'Transport',
          type: CategoryType.expense,
          icon: 'directions_bus',
          color: 0xFFF97316, // Orange-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatBillsId,
          userId: kDemoUserId,
          name: 'Bills',
          type: CategoryType.expense,
          icon: 'receipt_long',
          color: 0xFFEAB308, // Yellow-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatShoppingId,
          userId: kDemoUserId,
          name: 'Shopping',
          type: CategoryType.expense,
          icon: 'shopping_bag',
          color: 0xFFEC4899, // Pink-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatEducationId,
          userId: kDemoUserId,
          name: 'Education',
          type: CategoryType.expense,
          icon: 'school',
          color: 0xFF8B5CF6, // Purple-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatHealthId,
          userId: kDemoUserId,
          name: 'Health',
          type: CategoryType.expense,
          icon: 'medical_services',
          color: 0xFF06B6D4, // Cyan-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatEntertainmentId,
          userId: kDemoUserId,
          name: 'Entertainment',
          type: CategoryType.expense,
          icon: 'movie',
          color: 0xFF3B82F6, // Blue-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatExpenseOtherId,
          userId: kDemoUserId,
          name: 'Other',
          type: CategoryType.expense,
          icon: 'more_horiz',
          color: 0xFF64748B, // Slate-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        // Income categories
        AppCategory(
          id: kCatProjectEarningId,
          userId: kDemoUserId,
          name: 'Project Earning',
          type: CategoryType.income,
          icon: 'work',
          color: 0xFF10B981, // Emerald-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatPocketMoneyId,
          userId: kDemoUserId,
          name: 'Pocket Money',
          type: CategoryType.income,
          icon: 'account_balance_wallet',
          color: 0xFF14B8A6, // Teal-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
        AppCategory(
          id: kCatIncomeOtherId,
          userId: kDemoUserId,
          name: 'Other',
          type: CategoryType.income,
          icon: 'attach_money',
          color: 0xFF22C55E, // Green-500
          isDefault: true,
          createdAt: _now.subtract(const Duration(days: 30)),
          updatedAt: _now.subtract(const Duration(days: 30)),
        ),
      ];

  static List<TransactionEntry> get initialTransactions => [
        TransactionEntry(
          id: 'tx_01',
          userId: kDemoUserId,
          walletId: kWalletSavingsId,
          categoryId: kCatProjectEarningId,
          type: TransactionType.income,
          amount: 45000,
          note: 'Mobile app UI client milestone',
          date: _now.subtract(const Duration(days: 3)),
          createdAt: _now.subtract(const Duration(days: 3)),
          updatedAt: _now.subtract(const Duration(days: 3)),
        ),
        TransactionEntry(
          id: 'tx_02',
          userId: kDemoUserId,
          walletId: kWalletMobileId,
          categoryId: kCatBillsId,
          type: TransactionType.expense,
          amount: 4800,
          note: 'Home internet & electricity',
          date: _now.subtract(const Duration(days: 2)),
          createdAt: _now.subtract(const Duration(days: 2)),
          updatedAt: _now.subtract(const Duration(days: 2)),
        ),
        TransactionEntry(
          id: 'tx_03',
          userId: kDemoUserId,
          walletId: kWalletCashId,
          categoryId: kCatFoodId,
          type: TransactionType.expense,
          amount: 1850,
          note: 'Family dinner & biryani',
          date: _now.subtract(const Duration(days: 1)),
          createdAt: _now.subtract(const Duration(days: 1)),
          updatedAt: _now.subtract(const Duration(days: 1)),
        ),
        TransactionEntry(
          id: 'tx_04',
          userId: kDemoUserId,
          walletId: kWalletMobileId,
          categoryId: kCatTransportId,
          type: TransactionType.expense,
          amount: 950,
          note: 'Careem ride to office',
          date: _now,
          createdAt: _now,
          updatedAt: _now,
        ),
        TransactionEntry(
          id: 'tx_05',
          userId: kDemoUserId,
          walletId: kWalletCashId,
          categoryId: kCatShoppingId,
          type: TransactionType.expense,
          amount: 2200,
          note: 'Notebooks and stationary',
          date: _now,
          createdAt: _now,
          updatedAt: _now,
        ),
      ];

  static List<Transfer> get initialTransfers => [
        Transfer(
          id: 'tr_01',
          userId: kDemoUserId,
          fromWalletId: kWalletSavingsId,
          toWalletId: kWalletMobileId,
          amount: 5000,
          note: 'Monthly Easypaisa top-up',
          date: _now.subtract(const Duration(days: 5)),
          createdAt: _now.subtract(const Duration(days: 5)),
          updatedAt: _now.subtract(const Duration(days: 5)),
        ),
        Transfer(
          id: 'tr_02',
          userId: kDemoUserId,
          fromWalletId: kWalletMobileId,
          toWalletId: kWalletCashId,
          amount: 3000,
          note: 'Cash out from agent',
          date: _now.subtract(const Duration(days: 2)),
          createdAt: _now.subtract(const Duration(days: 2)),
          updatedAt: _now.subtract(const Duration(days: 2)),
        ),
      ];

  static List<Budget> get initialBudgets {
    final monthKey =
        '${_now.year.toString().padLeft(4, '0')}-${_now.month.toString().padLeft(2, '0')}';
    return [
      Budget(
        id: 'bg_total',
        userId: kDemoUserId,
        month: monthKey,
        mode: BudgetMode.both,
        categoryId: null,
        amount: 35000, // Total monthly budget: Rs 35,000
        createdAt: _now.subtract(const Duration(days: 10)),
        updatedAt: _now.subtract(const Duration(days: 10)),
      ),
      Budget(
        id: 'bg_food',
        userId: kDemoUserId,
        month: monthKey,
        mode: BudgetMode.both,
        categoryId: kCatFoodId,
        amount: 15000, // Food budget: Rs 15,000
        createdAt: _now.subtract(const Duration(days: 10)),
        updatedAt: _now.subtract(const Duration(days: 10)),
      ),
      Budget(
        id: 'bg_transport',
        userId: kDemoUserId,
        month: monthKey,
        mode: BudgetMode.both,
        categoryId: kCatTransportId,
        amount: 6000, // Transport budget: Rs 6,000
        createdAt: _now.subtract(const Duration(days: 10)),
        updatedAt: _now.subtract(const Duration(days: 10)),
      ),
      Budget(
        id: 'bg_bills',
        userId: kDemoUserId,
        month: monthKey,
        mode: BudgetMode.both,
        categoryId: kCatBillsId,
        amount: 8000, // Bills budget: Rs 8,000
        createdAt: _now.subtract(const Duration(days: 10)),
        updatedAt: _now.subtract(const Duration(days: 10)),
      ),
    ];
  }

  static List<Udhaar> get initialUdhaar => [
        Udhaar(
          id: 'udh_01',
          userId: kDemoUserId,
          personName: 'Ahmed Raza',
          amount: 3500,
          direction: UdhaarDirection.take,
          dueDate: _now.add(const Duration(days: 2)),
          status: UdhaarStatus.pending,
          note: 'Lent for semester fee short balance',
          notificationId: 101,
          createdAt: _now.subtract(const Duration(days: 4)),
          updatedAt: _now.subtract(const Duration(days: 4)),
        ),
        Udhaar(
          id: 'udh_02',
          userId: kDemoUserId,
          personName: 'Usman Tariq',
          amount: 1500,
          direction: UdhaarDirection.give,
          dueDate: _now.add(const Duration(days: 5)),
          status: UdhaarStatus.pending,
          note: 'Shared cafe bill contribution',
          notificationId: 102,
          createdAt: _now.subtract(const Duration(days: 1)),
          updatedAt: _now.subtract(const Duration(days: 1)),
        ),
        Udhaar(
          id: 'udh_03',
          userId: kDemoUserId,
          personName: 'Hamza Khan',
          amount: 2000,
          direction: UdhaarDirection.take,
          dueDate: _now.subtract(const Duration(days: 3)),
          status: UdhaarStatus.settled,
          note: 'Weekend road trip fuel share (settled)',
          notificationId: 103,
          createdAt: _now.subtract(const Duration(days: 10)),
          updatedAt: _now.subtract(const Duration(days: 3)),
        ),
      ];
}
